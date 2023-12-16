import { TypographySizes } from "@/components/commonTypes";

type HeadingProps = {
  children: string;
  size?: TypographySizes;
};

const Heading = ({ children }: HeadingProps): JSX.Element => {
  return <h1 className="text-lg">The quick brown fox ...</h1>;
};

export default Heading;
