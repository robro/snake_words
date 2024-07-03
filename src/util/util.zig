const std = @import("std");

pub fn randomChar() u8 {
    return std.crypto.random.uintLessThan(u8, 26) + 97;
}

pub const words: []const []const u8 = &.{
    "album",
    "virus",
    "event",
    "award",
    "front",
    "issue",
    "grace",
    "steam",
    "south",
    "which",
    "broad",
    "harsh",
    "plate",
    "greet",
    "array",
    "count",
    "limit",
    "image",
    "truth",
    "fully",
    "point",
    "green",
    "suite",
    "throw",
    "speed",
    "field",
    "short",
    "arise",
    "begin",
    "share",
    "given",
    "movie",
    "seven",
    "wheel",
    "chest",
    "ideal",
    "plant",
    "ahead",
    "rival",
    "burst",
    "moral",
    "ready",
    "input",
    "empty",
    "argue",
    "begun",
    "legal",
    "extra",
    "tools",
    "users",
    "motor",
    "crash",
    "faith",
    "clean",
    "width",
    "dealt",
    "globe",
    "quite",
    "bonus",
    "state",
    "prior",
    "admit",
    "stick",
    "usual",
    "scene",
    "smile",
    "party",
    "coach",
    "eager",
    "river",
    "other",
    "stood",
    "catch",
    "mount",
    "nurse",
    "three",
    "eight",
    "magic",
    "story",
    "entry",
    "first",
    "north",
    "check",
    "under",
    "error",
    "bland",
    "basis",
    "match",
    "actor",
    "cream",
    "chair",
    "plane",
    "stand",
    "craft",
    "table",
    "major",
    "email",
    "bless",
    "spent",
    "draft",
    "inner",
    "forth",
    "newly",
    "occur",
    "total",
    "began",
    "paint",
    "teach",
    "chase",
    "sound",
    "delay",
    "trace",
    "black",
    "dance",
    "white",
    "below",
    "queen",
    "trend",
    "ratio",
    "super",
    "women",
    "arena",
    "usage",
    "there",
    "place",
    "every",
    "tight",
    "local",
    "candy",
    "being",
    "buyer",
    "smart",
    "spoke",
    "leave",
    "exist",
    "pages",
    "drove",
    "young",
    "tough",
    "floor",
    "plain",
    "study",
    "built",
    "early",
    "cheap",
    "audio",
    "stake",
    "clear",
    "times",
    "solve",
    "still",
    "camel",
    "drill",
    "break",
    "human",
    "april",
    "vital",
    "prize",
    "twice",
    "using",
    "march",
    "posts",
    "grape",
    "equal",
    "raise",
    "tower",
    "video",
    "month",
    "round",
    "title",
    "agent",
    "rural",
    "about",
    "zebra",
    "piano",
    "fixed",
    "doubt",
    "zeros",
    "wilds",
    "offer",
    "alike",
    "mouse",
    "cheat",
    "grant",
    "graph",
    "shine",
    "happy",
    "aside",
    "heart",
    "truly",
    "solid",
    "chain",
    "apply",
    "radio",
    "yours",
    "shelf",
    "gross",
    "world",
    "fresh",
    "alarm",
    "voice",
    "hills",
    "crazy",
    "terms",
    "badly",
    "dream",
    "minor",
    "maker",
    "wrote",
    "court",
    "blast",
    "books",
    "chimp",
    "adopt",
    "words",
    "space",
    "alter",
    "wires",
    "hobby",
    "sharp",
    "focus",
    "sugar",
    "split",
    "sleep",
    "pitch",
    "lying",
    "fraud",
    "rapid",
    "bagel",
    "adult",
    "fruit",
    "mixed",
    "speak",
    "above",
    "boast",
    "scope",
    "sense",
    "based",
    "group",
    "minus",
    "fleet",
    "years",
    "fifth",
    "water",
    "shoot",
    "chief",
    "chord",
    "claim",
    "might",
    "child",
    "thank",
    "along",
    "glass",
    "lunch",
    "china",
    "style",
    "grown",
    "trial",
    "apple",
    "night",
    "score",
    "rough",
    "think",
    "drink",
    "honor",
    "stone",
    "giant",
    "cloth",
    "blind",
    "yield",
    "earth",
    "drama",
    "bring",
    "flash",
    "guard",
    "laugh",
    "level",
    "angry",
    "carry",
    "crowd",
    "guess",
    "curve",
    "small",
    "right",
    "proud",
    "items",
    "great",
    "abuse",
    "never",
    "route",
    "hence",
    "booth",
    "agree",
    "clock",
    "depth",
    "false",
    "brief",
    "elite",
    "until",
    "label",
    "beach",
    "sorry",
    "stage",
    "apart",
    "sport",
    "reply",
    "cycle",
    "doing",
    "allow",
    "again",
    "steal",
    "audit",
    "going",
    "touch",
    "shirt",
    "staff",
    "dress",
    "trade",
    "alone",
    "those",
    "aware",
    "truck",
    "grand",
    "clerk",
    "refer",
    "wiped",
    "guide",
    "avoid",
    "frame",
    "order",
    "track",
    "upset",
    "strip",
    "model",
    "alive",
    "needs",
    "mayor",
    "cause",
    "media",
    "topic",
    "wound",
    "scale",
    "price",
    "music",
    "phase",
    "shall",
    "urban",
    "steel",
    "forty",
    "reach",
    "crown",
    "bound",
    "valid",
    "logic",
    "loose",
    "brand",
    "range",
    "broke",
    "metal",
    "since",
    "proof",
    "links",
    "fluid",
    "storm",
    "angle",
    "click",
    "write",
    "daily",
    "could",
    "wrist",
    "acute",
    "alert",
    "press",
    "blend",
    "laser",
    "fiber",
    "prove",
    "quick",
    "spike",
    "brain",
    "smoke",
    "block",
    "sheet",
    "phone",
    "coast",
    "skill",
    "games",
    "waste",
    "lucky",
    "trust",
    "judge",
    "found",
    "board",
    "blank",
    "dozen",
    "large",
    "pride",
    "fault",
    "start",
    "ought",
    "mouth",
    "photo",
    "weird",
    "train",
    "pilot",
    "force",
    "exact",
    "voted",
    "guest",
    "brown",
    "treat",
    "trail",
    "index",
    "dated",
    "peace",
    "would",
    "joint",
    "theme",
    "basic",
    "asset",
    "shift",
    "frank",
    "layer",
    "after",
    "their",
    "cable",
    "blame",
    "tried",
    "crime",
    "oasis",
    "fifty",
    "panel",
    "stuff",
    "slide",
    "final",
    "forum",
    "house",
    "third",
    "bread",
    "maybe",
    "ocean",
    "whose",
    "hotel",
    "quiet",
    "breed",
    "drive",
    "sites",
    "grill",
    "blood",
    "slice",
    "grass",
    "cross",
    "print",
    "heavy",
    "whole",
    "wrong",
    "drawn",
    "stock",
    "light",
    "build",
    "prime",
    "shell",
    "youth",
    "dying",
    "learn",
    "money",
    "winds",
    "charm",
    "among",
    "enjoy",
    "hours",
    "enter",
    "serve",
    "funny",
    "store",
    "visit",
    "meant",
    "shape",
    "piece",
    "pound",
    "cover",
    "while",
    "class",
    "noise",
    "least",
    "known",
    "often",
    "debut",
    "royal",
    "novel",
    "cheer",
    "power",
    "later",
    "noted",
    "these",
    "paper",
    "value",
    "smith",
    "woman",
    "taken",
    "cloud",
    "watch",
    "spend",
    "close",
    "today",
    "enemy",
    "death",
    "grade",
    "anger",
    "sales",
    "taste",
    "where",
    "fight",
};
