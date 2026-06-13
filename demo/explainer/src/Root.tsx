import { Composition } from "remotion";
import { Explainer } from "./Explainer";

export const RemotionRoot = () => {
  return (
    <Composition
      id="Explainer"
      component={Explainer}
      durationInFrames={810}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
