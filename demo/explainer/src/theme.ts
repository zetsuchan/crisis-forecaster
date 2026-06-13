import { loadFont } from "@remotion/google-fonts/Inter";

export const { fontFamily } = loadFont();

export const theme = {
  bg: "#0B0B0F",
  bgSoft: "#15151C",
  text: "#F5F5F7",
  subtle: "#9A9AA8",
  // Risk palette (matches the app)
  red: "#FF453A",
  orange: "#FF9F0A",
  green: "#30D158",
  // Brand accents
  claude: "#FF8A5B", // Anthropic-ish warm
  apple: "#E5E5EA",
  blue: "#0A84FF",
  card: "#1C1C26",
  stroke: "rgba(255,255,255,0.10)",
} as const;
