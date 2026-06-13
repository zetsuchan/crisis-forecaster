import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { fontFamily, theme } from "./theme";

// ---------- shared bits ----------

const Background: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <AbsoluteFill
    style={{
      backgroundColor: theme.bg,
      backgroundImage:
        "radial-gradient(120% 80% at 50% -10%, rgba(255,138,91,0.10), transparent 60%)",
      fontFamily,
      color: theme.text,
      justifyContent: "center",
      alignItems: "center",
      padding: 120,
    }}
  >
    {children}
  </AbsoluteFill>
);

const useEntrance = (delay = 0, config = { damping: 200 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - delay, fps, config });
};

// ---------- Scene 1: Title ----------

const Title: React.FC = () => {
  const t = useEntrance(0);
  const sub = useEntrance(12);
  const tag = useEntrance(24);
  return (
    <Background>
      <div style={{ textAlign: "center" }}>
        <div
          style={{
            fontSize: 120,
            fontWeight: 800,
            letterSpacing: -2,
            opacity: t,
            transform: `translateY(${interpolate(t, [0, 1], [30, 0])}px)`,
          }}
        >
          Crisis Forecaster
        </div>
        <div
          style={{
            fontSize: 44,
            color: theme.subtle,
            marginTop: 24,
            opacity: sub,
          }}
        >
          A Siri-native crisis early-warning agent for sickle cell disease
        </div>
        <div
          style={{
            marginTop: 48,
            fontSize: 26,
            color: theme.claude,
            fontWeight: 600,
            opacity: tag,
            letterSpacing: 1,
          }}
        >
          ANTHROPIC HACKATHON 2026
        </div>
      </div>
    </Background>
  );
};

// ---------- Scene 2: Problem ----------

const Chip: React.FC<{ label: string; delay: number; tint: string }> = ({
  label,
  delay,
  tint,
}) => {
  const e = useEntrance(delay, { damping: 18, stiffness: 200 });
  return (
    <div
      style={{
        fontSize: 34,
        fontWeight: 600,
        padding: "16px 28px",
        borderRadius: 999,
        background: theme.card,
        border: `1px solid ${theme.stroke}`,
        color: tint,
        opacity: e,
        transform: `scale(${interpolate(e, [0, 1], [0.7, 1])})`,
      }}
    >
      {label}
    </div>
  );
};

const Problem: React.FC = () => {
  const t = useEntrance(0);
  return (
    <Background>
      <div style={{ textAlign: "center", maxWidth: 1400 }}>
        <div
          style={{
            fontSize: 60,
            fontWeight: 800,
            lineHeight: 1.15,
            opacity: t,
            transform: `translateY(${interpolate(t, [0, 1], [24, 0])}px)`,
          }}
        >
          Vaso-occlusive crises don't come from nowhere.
        </div>
        <div style={{ fontSize: 34, color: theme.subtle, marginTop: 24, opacity: t }}>
          The body and the weather leave signals first.
        </div>
        <div
          style={{
            display: "flex",
            flexWrap: "wrap",
            gap: 20,
            justifyContent: "center",
            marginTop: 60,
          }}
        >
          <Chip label="Resting HR ↑" delay={24} tint={theme.orange} />
          <Chip label="HRV ↓" delay={32} tint={theme.orange} />
          <Chip label="SpO₂ ↓" delay={40} tint={theme.red} />
          <Chip label="Sleep fragmenting" delay={48} tint={theme.orange} />
          <Chip label="Pressure dropping" delay={56} tint={theme.blue} />
          <Chip label="Low humidity" delay={64} tint={theme.blue} />
        </div>
      </div>
    </Background>
  );
};

// ---------- Scene 3: Architecture ----------

const Node: React.FC<{
  title: string;
  lines: string[];
  delay: number;
  accent: string;
}> = ({ title, lines, delay, accent }) => {
  const e = useEntrance(delay, { damping: 18, stiffness: 180 });
  return (
    <div
      style={{
        width: 320,
        minHeight: 230,
        borderRadius: 28,
        background: theme.card,
        border: `1px solid ${theme.stroke}`,
        boxShadow: `0 0 0 2px ${accent}22, 0 20px 60px rgba(0,0,0,0.4)`,
        padding: 28,
        display: "flex",
        flexDirection: "column",
        gap: 10,
        opacity: e,
        transform: `translateY(${interpolate(e, [0, 1], [40, 0])}px) scale(${interpolate(
          e,
          [0, 1],
          [0.9, 1]
        )})`,
      }}
    >
      <div style={{ fontSize: 30, fontWeight: 800, color: accent }}>{title}</div>
      {lines.map((l) => (
        <div key={l} style={{ fontSize: 24, color: theme.subtle, lineHeight: 1.3 }}>
          {l}
        </div>
      ))}
    </div>
  );
};

const Arrow: React.FC<{ delay: number }> = ({ delay }) => {
  const e = useEntrance(delay);
  return (
    <div
      style={{
        fontSize: 56,
        color: theme.subtle,
        opacity: e,
        transform: `translateX(${interpolate(e, [0, 1], [-16, 0])}px)`,
      }}
    >
      →
    </div>
  );
};

const Architecture: React.FC = () => {
  const t = useEntrance(0);
  const caption = useEntrance(70);
  return (
    <Background>
      <div style={{ width: "100%", textAlign: "center" }}>
        <div style={{ fontSize: 40, fontWeight: 700, color: theme.subtle, opacity: t }}>
          Two models. One clean division of labor.
        </div>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 18,
            marginTop: 56,
          }}
        >
          <Node
            title="Signals"
            lines={["HealthKit vitals", "WeatherKit", "Your check-in"]}
            delay={8}
            accent={theme.blue}
          />
          <Arrow delay={20} />
          <Node
            title="Apple · on-device"
            lines={["Private triage", "Reads your words", "Decides escalation"]}
            delay={28}
            accent={theme.apple}
          />
          <Arrow delay={40} />
          <Node
            title="Claude Opus 4.8"
            lines={["24–72h forecast", "Plain-language why", "Drafts the Passport"]}
            delay={48}
            accent={theme.claude}
          />
          <Arrow delay={60} />
          <Node
            title="Delivered"
            lines={["Siri, app closed", "Lock-screen widget", "ER handoff staged"]}
            delay={68}
            accent={theme.green}
          />
        </div>
        <div
          style={{
            fontSize: 30,
            color: theme.text,
            marginTop: 56,
            opacity: caption,
          }}
        >
          Private on-device triage → frontier reasoning → ambient delivery.
        </div>
      </div>
    </Background>
  );
};

// ---------- Scene 4: Division ----------

const Column: React.FC<{
  head: string;
  body: string;
  delay: number;
  accent: string;
}> = ({ head, body, delay, accent }) => {
  const e = useEntrance(delay, { damping: 200 });
  return (
    <div
      style={{
        flex: 1,
        opacity: e,
        transform: `translateY(${interpolate(e, [0, 1], [30, 0])}px)`,
        textAlign: "center",
        padding: "0 24px",
      }}
    >
      <div style={{ fontSize: 40, fontWeight: 800, color: accent }}>{head}</div>
      <div style={{ fontSize: 28, color: theme.subtle, marginTop: 16, lineHeight: 1.35 }}>
        {body}
      </div>
    </div>
  );
};

const Division: React.FC = () => {
  return (
    <Background>
      <div style={{ display: "flex", width: "100%", alignItems: "flex-start" }}>
        <Column
          head="Claude reasons"
          body="Opus 4.8 fuses the signals and explains the risk like a friend who understands."
          delay={4}
          accent={theme.claude}
        />
        <Column
          head="Apple triages"
          body="The on-device model reads your check-in privately — nothing leaves the phone."
          delay={16}
          accent={theme.apple}
        />
        <Column
          head="iOS 27 delivers"
          body="App Intents put it in Siri and on the Lock Screen. You never open the app."
          delay={28}
          accent={theme.green}
        />
      </div>
    </Background>
  );
};

// ---------- Scene 5: Close ----------

const Close: React.FC = () => {
  const a = useEntrance(0);
  const b = useEntrance(16);
  const c = useEntrance(40);
  return (
    <Background>
      <div style={{ textAlign: "center" }}>
        <div
          style={{
            fontSize: 64,
            fontWeight: 700,
            color: theme.subtle,
            opacity: a,
            transform: `translateY(${interpolate(a, [0, 1], [20, 0])}px)`,
          }}
        >
          Prediction is the feature.
        </div>
        <div
          style={{
            fontSize: 84,
            fontWeight: 900,
            marginTop: 16,
            opacity: b,
            transform: `translateY(${interpolate(b, [0, 1], [20, 0])}px)`,
          }}
        >
          The Passport is the moat.
        </div>
        <div style={{ fontSize: 28, color: theme.subtle, marginTop: 56, opacity: c }}>
          github.com/zetsuchan/crisis-forecaster
        </div>
      </div>
    </Background>
  );
};

// ---------- Composition ----------

export const Explainer: React.FC = () => {
  const f = (n: number) => linearTiming({ durationInFrames: n });
  return (
    <AbsoluteFill style={{ backgroundColor: theme.bg }}>
      <TransitionSeries>
        <TransitionSeries.Sequence durationInFrames={90}>
          <Title />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={f(15)} />
        <TransitionSeries.Sequence durationInFrames={180}>
          <Problem />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={f(15)} />
        <TransitionSeries.Sequence durationInFrames={270}>
          <Architecture />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={f(15)} />
        <TransitionSeries.Sequence durationInFrames={150}>
          <Division />
        </TransitionSeries.Sequence>
        <TransitionSeries.Transition presentation={fade()} timing={f(15)} />
        <TransitionSeries.Sequence durationInFrames={180}>
          <Close />
        </TransitionSeries.Sequence>
      </TransitionSeries>
    </AbsoluteFill>
  );
};
