import { useParams } from "react-router-dom";

const EditSource = (): JSX.Element => {
  const { sourceId } = useParams();

  return <div> Edit Source : {sourceId}</div>;
};

export default EditSource;
