import { Ok, Error as ResultError, CustomType, Empty, NonEmpty, BitArray } from "../../../gleam_stdlib/gleam.mjs";
import { LoadGames } from "../../api/to_server.mjs";
import { LoadGame } from "../../api/to_server.mjs";
import { LoadStandings } from "../../api/to_server.mjs";
import { LoadTeam } from "../../api/to_server.mjs";
import { LoadAdminGames } from "../../api/to_server.mjs";
import { UpdateScore } from "../../api/to_server.mjs";
import { MarkFinal } from "../../api/to_server.mjs";
import { CorrectResult } from "../../api/to_server.mjs";
import { GamesLoaded } from "../../api/to_client.mjs";
import { GameLoaded } from "../../api/to_client.mjs";
import { StandingsLoaded } from "../../api/to_client.mjs";
import { PowerRankingsLoaded } from "../../api/to_client.mjs";
import { GamesLoadFailed } from "../../api/to_client.mjs";
import { TeamLoaded } from "../../api/to_client.mjs";
import { AdminGamesLoaded } from "../../api/to_client.mjs";
import { GameUpdated } from "../../api/to_client.mjs";
import { ScoreUpdateSaved } from "../../api/to_client.mjs";
import { ResultSaved } from "../../api/to_client.mjs";
import { AdminError } from "../../api/to_client.mjs";
import { TeamDetail } from "../../api/domain/team.mjs";
import { PowerRankingRow } from "../../api/domain/standing.mjs";
import { StandingRow } from "../../api/domain/standing.mjs";
import { AdminGameDetail } from "../../api/domain/game.mjs";
import { AdminGameSummary } from "../../api/domain/game.mjs";
import { GameSnapshot } from "../../api/domain/game.mjs";
import { GameDetail } from "../../api/domain/game.mjs";
import { PublicGameSummary } from "../../api/domain/game.mjs";
import { Team } from "../../api/domain/game.mjs";
import { Scheduled } from "../../api/domain/game.mjs";
import { Live } from "../../api/domain/game.mjs";
import { Final } from "../../api/domain/game.mjs";

const constructorRegistry = new Map();

function registerConstructor(atomName, ctor, fieldCount, fieldTypes) {
  constructorRegistry.set(atomName, { ctor, fieldCount, fieldTypes });
}

function arrayToGleamList(items) {
  let list = new Empty();
  for (let i = items.length - 1; i >= 0; i -= 1) {
    list = new NonEmpty(items[i], list);
  }
  return list;
}

function gleamListToArray(list) {
  const items = [];
  let current = list;
  while (current instanceof NonEmpty) {
    items.push(current.head);
    current = current.tail;
  }
  return items;
}

const textEncoder = new TextEncoder();
const textDecoder = new TextDecoder();

class Decoder {
  constructor(input) {
    if (input instanceof Uint8Array) {
      this.bytes = input;
    } else if (input instanceof ArrayBuffer) {
      this.bytes = new Uint8Array(input);
    } else if (input && input.rawBuffer instanceof Uint8Array) {
      this.bytes = input.rawBuffer;
    } else {
      throw new Error("ETF decode expected ArrayBuffer, Uint8Array, or BitArray");
    }
    this.view = new DataView(this.bytes.buffer, this.bytes.byteOffset, this.bytes.byteLength);
    this.offset = 0;
  }

  decode() {
    const version = this.readUint8();
    if (version !== 131) throw new Error("ETF decode expected version byte 131");
    const value = this.decodeTerm();
    if (this.offset !== this.bytes.byteLength) throw new Error("ETF decode found trailing bytes");
    return value;
  }

  ensureAvailable(size) {
    if (this.offset + size > this.bytes.byteLength) throw new Error("ETF decode input ended early");
  }

  readUint8() {
    this.ensureAvailable(1);
    const value = this.view.getUint8(this.offset);
    this.offset += 1;
    return value;
  }

  readUint16() {
    this.ensureAvailable(2);
    const value = this.view.getUint16(this.offset);
    this.offset += 2;
    return value;
  }

  readUint32() {
    this.ensureAvailable(4);
    const value = this.view.getUint32(this.offset);
    this.offset += 4;
    return value;
  }

  readInt32() {
    this.ensureAvailable(4);
    const value = this.view.getInt32(this.offset);
    this.offset += 4;
    return value;
  }

  readFloat64() {
    this.ensureAvailable(8);
    const value = this.view.getFloat64(this.offset);
    this.offset += 8;
    return value;
  }

  readBytes(size) {
    this.ensureAvailable(size);
    const value = this.bytes.slice(this.offset, this.offset + size);
    this.offset += size;
    return value;
  }

  readString(size) {
    return textDecoder.decode(this.readBytes(size));
  }

  decodeTerm(typeHint = undefined) {
    const tag = this.readUint8();
    switch (tag) {
      case 70:
        return this.readFloat64();
      case 97:
        return this.readUint8();
      case 98:
        return this.readInt32();
      case 104:
        return this.decodeTuple(this.readUint8(), typeHint);
      case 105:
        return this.decodeTuple(this.readUint32(), typeHint);
      case 106:
        return new Empty();
      case 107:
        return this.decodeStringList();
      case 108:
        return this.decodeList(typeHint);
      case 109:
        return this.decodeBinary(typeHint);
      case 110:
        return this.decodeBigInt(this.readUint8());
      case 111:
        return this.decodeBigInt(this.readUint32());
      case 118:
        return this.decodeAtom(this.readUint16());
      case 119:
        return this.decodeAtom(this.readUint8());
      case 77:
        return this.decodeBitArray();
      default:
        throw new Error("ETF decode unsupported tag " + tag);
    }
  }

  decodeAtom(size) {
    const atom = this.readString(size);
    if (atom === "true") return true;
    if (atom === "false") return false;
    if (atom === "nil" || atom === "undefined") return undefined;
    const registered = constructorRegistry.get(atom);
    if (registered && registered.fieldCount === 0) return new registered.ctor();
    return atom;
  }

  decodeBinary(typeHint) {
    const bytes = this.readBytes(this.readUint32());
    if (typeHint === "bit_array") return new BitArray(bytes);
    return textDecoder.decode(bytes);
  }

  decodeTuple(arity, typeHint = undefined) {
    if (arity === 0) return [];
    const tupleHints = typeHint?.kind === "tuple" ? typeHint.elements : undefined;
    const atom = this.decodeTerm(tupleHints?.[0]);
    const registered = typeof atom === "string" ? constructorRegistry.get(atom) : undefined;
    if (registered) {
      const fields = [];
      for (let i = 1; i < arity; i += 1) fields.push(this.decodeTerm(registered.fieldTypes?.[i - 1]));
      while (fields.length < registered.fieldCount) fields.push(undefined);
      fields.length = registered.fieldCount;
      return new registered.ctor(...fields);
    }
    const items = [atom];
    for (let i = 1; i < arity; i += 1) items.push(this.decodeTerm(tupleHints?.[i]));
    if (atom === "ok") return new Ok(items[1]);
    if (atom === "error") return new ResultError(items[1]);
    return items;
  }

  decodeStringList() {
    const size = this.readUint16();
    const items = [];
    for (let i = 0; i < size; i += 1) items.push(this.readUint8());
    return arrayToGleamList(items);
  }

  decodeList(typeHint = undefined) {
    const size = this.readUint32();
    const items = [];
    const elementHint = typeHint?.kind === "list" ? typeHint.element : undefined;
    for (let i = 0; i < size; i += 1) items.push(this.decodeTerm(elementHint));
    if (this.readUint8() !== 106) throw new Error("ETF decode found improper list");
    return arrayToGleamList(items);
  }

  decodeBigInt(size) {
    const sign = this.readUint8();
    const digits = this.readBytes(size);
    let value = 0n;
    for (let i = size - 1; i >= 0; i -= 1) value = (value << 8n) | BigInt(digits[i]);
    if (sign === 1) value = -value;
    if (value >= Number.MIN_SAFE_INTEGER && value <= Number.MAX_SAFE_INTEGER) return Number(value);
    return value;
  }

  decodeBitArray() {
    const size = this.readUint32();
    const bitsInLastByte = this.readUint8();
    const bytes = this.readBytes(size);
    const bitSize = size === 0 ? 0 : (size - 1) * 8 + bitsInLastByte;
    return new BitArray(bytes, bitSize, 0);
  }
}

class Encoder {
  constructor() {
    this.buffer = new ArrayBuffer(1024);
    this.view = new DataView(this.buffer);
    this.bytes = new Uint8Array(this.buffer);
    this.offset = 0;
  }

  ensureCapacity(size) {
    const required = this.offset + size;
    if (required <= this.buffer.byteLength) return;
    let nextSize = this.buffer.byteLength;
    while (nextSize < required) nextSize *= 2;
    const nextBuffer = new ArrayBuffer(nextSize);
    new Uint8Array(nextBuffer).set(this.bytes);
    this.buffer = nextBuffer;
    this.view = new DataView(this.buffer);
    this.bytes = new Uint8Array(this.buffer);
  }

  writeUint8(value) {
    this.ensureCapacity(1);
    this.view.setUint8(this.offset, value);
    this.offset += 1;
  }

  writeUint16(value) {
    this.ensureCapacity(2);
    this.view.setUint16(this.offset, value);
    this.offset += 2;
  }

  writeUint32(value) {
    this.ensureCapacity(4);
    this.view.setUint32(this.offset, value);
    this.offset += 4;
  }

  writeInt32(value) {
    this.ensureCapacity(4);
    this.view.setInt32(this.offset, value);
    this.offset += 4;
  }

  writeFloat64(value) {
    this.ensureCapacity(8);
    this.view.setFloat64(this.offset, value);
    this.offset += 8;
  }

  writeBytes(bytes) {
    this.ensureCapacity(bytes.length);
    this.bytes.set(bytes, this.offset);
    this.offset += bytes.length;
  }

  result() {
    return this.buffer.slice(0, this.offset);
  }

  encodeTerm(value, typeHint = undefined) {
    if (value === undefined || value === null) return this.writeAtom("nil");
    if (typeof value === "boolean") return this.writeAtom(value ? "true" : "false");
    if (typeof value === "string") return this.writeBinary(value);
    if (typeof value === "number") return this.writeNumber(value, typeHint);
    if (typeof value === "bigint") return this.writeBigInt(value);
    if (value instanceof Empty || value instanceof NonEmpty) return this.writeList(gleamListToArray(value), typeHint);
    if (value && value.rawBuffer instanceof Uint8Array) return this.writeBitArray(value);
    if (Array.isArray(value)) return this.writeTuple(value, typeHint);
    if (value instanceof CustomType) return this.writeCustomType(value, typeHint);
    throw new Error("ETF encode unsupported value " + String(value));
  }

  writeAtom(atom) {
    const bytes = textEncoder.encode(atom);
    if (bytes.length <= 255) {
      this.writeUint8(119);
      this.writeUint8(bytes.length);
    } else {
      this.writeUint8(118);
      this.writeUint16(bytes.length);
    }
    this.writeBytes(bytes);
  }

  writeBinary(value) {
    const bytes = textEncoder.encode(value);
    this.writeUint8(109);
    this.writeUint32(bytes.length);
    this.writeBytes(bytes);
  }

  writeNumber(value, typeHint) {
    if (typeHint === "float" || !Number.isInteger(value)) {
      this.writeUint8(70);
      this.writeFloat64(value);
    } else if (value >= 0 && value <= 255) {
      this.writeUint8(97);
      this.writeUint8(value);
    } else if (value >= -2147483648 && value <= 2147483647) {
      this.writeUint8(98);
      this.writeInt32(value);
    } else {
      this.writeBigInt(BigInt(value));
    }
  }

  writeBigInt(value) {
    const sign = value < 0n ? 1 : 0;
    let abs = value < 0n ? -value : value;
    const digits = [];
    while (abs > 0n) {
      digits.push(Number(abs & 0xffn));
      abs >>= 8n;
    }
    if (digits.length < 256) {
      this.writeUint8(110);
      this.writeUint8(digits.length);
    } else {
      this.writeUint8(111);
      this.writeUint32(digits.length);
    }
    this.writeUint8(sign);
    this.writeBytes(new Uint8Array(digits));
  }

  writeList(items, typeHint) {
    if (items.length === 0) return this.writeUint8(106);
    this.writeUint8(108);
    this.writeUint32(items.length);
    const elementHint = typeHint?.kind === "list" ? typeHint.element : undefined;
    items.forEach(item => this.encodeTerm(item, elementHint));
    this.writeUint8(106);
  }

  writeBitArray(value) {
    if (value.bitSize !== undefined && value.bitSize % 8 !== 0) {
      this.writeUint8(77);
      this.writeUint32(value.rawBuffer.length);
      this.writeUint8(value.bitSize % 8);
      this.writeBytes(value.rawBuffer);
    } else {
      this.writeUint8(109);
      this.writeUint32(value.rawBuffer.length);
      this.writeBytes(value.rawBuffer);
    }
  }

  writeTuple(items, typeHint = undefined) {
    if (items.length <= 255) {
      this.writeUint8(104);
      this.writeUint8(items.length);
    } else {
      this.writeUint8(105);
      this.writeUint32(items.length);
    }
    const elementHints = typeHint?.kind === "tuple" ? typeHint.elements : undefined;
    items.forEach((item, index) => this.encodeTerm(item, elementHints?.[index]));
  }

  writeCustomType(value, typeHint = undefined) {
    const atom = customTypeAtom(value);
    const registered = constructorRegistry.get(atom);
    const fields = Object.keys(value).map(key => value[key]);
    if (fields.length === 0) return this.writeAtom(atom);
    const fieldTypes = optionFieldTypes(value, typeHint) ?? registered?.fieldTypes ?? [];
    if (fields.length + 1 <= 255) {
      this.writeUint8(104);
      this.writeUint8(fields.length + 1);
    } else {
      this.writeUint8(105);
      this.writeUint32(fields.length + 1);
    }
    this.writeAtom(atom);
    fields.forEach((field, index) => this.encodeTerm(field, fieldTypes[index]));
  }
}

function customTypeAtom(value) {
  if (value.constructor.__wireAtom !== undefined) return value.constructor.__wireAtom;
  throw new Error("ETF encode unsupported custom type " + value.constructor.name);
}

function optionFieldTypes(value, typeHint) {
  return undefined;
}

export function encode_value(value) {
  ensure();
  const encoder = new Encoder();
  encoder.writeUint8(131);
  encoder.encodeTerm(value);
  return new BitArray(new Uint8Array(encoder.result()));
}

export function decode_result(bytes) {
  try {
    ensure();
    return new Ok(new Decoder(bytes).decode());
  } catch (_) {
    return new ResultError(undefined);
  }
}

let installed = false;

export function ensure() {
  if (installed) return undefined;
  installed = true;
  Scheduled.__wireAtom = "scheduled";
  registerConstructor("scheduled", Scheduled, 0, []);
  Live.__wireAtom = "live";
  registerConstructor("live", Live, 1, ["string"]);
  Final.__wireAtom = "final";
  registerConstructor("final", Final, 0, []);
  Team.__wireAtom = "team";
  registerConstructor("team", Team, 3, ["string", "string", "string"]);
  PublicGameSummary.__wireAtom = "public_game_summary";
  registerConstructor("public_game_summary", PublicGameSummary, 6, ["int", undefined, undefined, "int", "int", undefined]);
  GameDetail.__wireAtom = "game_detail";
  registerConstructor("game_detail", GameDetail, 7, ["int", undefined, undefined, "int", "int", undefined, { kind: "list", element: "string" }]);
  GameSnapshot.__wireAtom = "game_snapshot";
  registerConstructor("game_snapshot", GameSnapshot, 6, ["int", undefined, undefined, "int", "int", undefined]);
  AdminGameSummary.__wireAtom = "admin_game_summary";
  registerConstructor("admin_game_summary", AdminGameSummary, 7, ["int", "string", "string", "int", "int", undefined, "bool"]);
  AdminGameDetail.__wireAtom = "admin_game_detail";
  registerConstructor("admin_game_detail", AdminGameDetail, 7, ["int", "string", "string", "int", "int", undefined, "string"]);
  StandingRow.__wireAtom = "standing_row";
  registerConstructor("standing_row", StandingRow, 7, ["string", "string", "string", "int", "int", "int", "int"]);
  PowerRankingRow.__wireAtom = "power_ranking_row";
  registerConstructor("power_ranking_row", PowerRankingRow, 7, ["string", "string", "string", "int", "int", "int", "int"]);
  TeamDetail.__wireAtom = "team_detail";
  registerConstructor("team_detail", TeamDetail, 8, ["string", "string", "string", "int", "int", "int", "int", { kind: "list", element: undefined }]);
  GamesLoaded.__wireAtom = "games_loaded";
  registerConstructor("games_loaded", GamesLoaded, 1, [{ kind: "list", element: undefined }]);
  GameLoaded.__wireAtom = "game_loaded";
  registerConstructor("game_loaded", GameLoaded, 1, [undefined]);
  StandingsLoaded.__wireAtom = "standings_loaded";
  registerConstructor("standings_loaded", StandingsLoaded, 1, [{ kind: "list", element: undefined }]);
  PowerRankingsLoaded.__wireAtom = "power_rankings_loaded";
  registerConstructor("power_rankings_loaded", PowerRankingsLoaded, 1, [{ kind: "list", element: undefined }]);
  GamesLoadFailed.__wireAtom = "games_load_failed";
  registerConstructor("games_load_failed", GamesLoadFailed, 1, ["string"]);
  TeamLoaded.__wireAtom = "team_loaded";
  registerConstructor("team_loaded", TeamLoaded, 1, [undefined]);
  AdminGamesLoaded.__wireAtom = "admin_games_loaded";
  registerConstructor("admin_games_loaded", AdminGamesLoaded, 1, [{ kind: "list", element: undefined }]);
  GameUpdated.__wireAtom = "game_updated";
  registerConstructor("game_updated", GameUpdated, 1, [undefined]);
  ScoreUpdateSaved.__wireAtom = "score_update_saved";
  registerConstructor("score_update_saved", ScoreUpdateSaved, 1, [undefined]);
  ResultSaved.__wireAtom = "result_saved";
  registerConstructor("result_saved", ResultSaved, 1, [undefined]);
  AdminError.__wireAtom = "admin_error";
  registerConstructor("admin_error", AdminError, 1, ["string"]);
  LoadGames.__wireAtom = "load_games";
  registerConstructor("load_games", LoadGames, 0, []);
  LoadGame.__wireAtom = "load_game";
  registerConstructor("load_game", LoadGame, 1, ["int"]);
  LoadStandings.__wireAtom = "load_standings";
  registerConstructor("load_standings", LoadStandings, 0, []);
  LoadTeam.__wireAtom = "load_team";
  registerConstructor("load_team", LoadTeam, 1, ["string"]);
  LoadAdminGames.__wireAtom = "load_admin_games";
  registerConstructor("load_admin_games", LoadAdminGames, 0, []);
  UpdateScore.__wireAtom = "update_score";
  registerConstructor("update_score", UpdateScore, 4, ["int", "int", "int", "string"]);
  MarkFinal.__wireAtom = "mark_final";
  registerConstructor("mark_final", MarkFinal, 1, ["int"]);
  CorrectResult.__wireAtom = "correct_result";
  registerConstructor("correct_result", CorrectResult, 3, ["int", "int", "int"]);
  return undefined;
}
