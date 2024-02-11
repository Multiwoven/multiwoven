import { Breadcrumb, BreadcrumbItem } from "@chakra-ui/react";
import { Step } from "./types";
import { Link } from "react-router-dom";

type BreadcrumbsProps = {
  steps: Step[];
};

const Breadcrumbs = ({ steps }: BreadcrumbsProps): JSX.Element => {
  return (
    <Breadcrumb separator="/" marginBottom="10px">
      {steps.map((step) => (
        <BreadcrumbItem key={step.name}>
          <Link to={step.url}>{step.name}</Link>
        </BreadcrumbItem>
      ))}
    </Breadcrumb>
  );
};

export default Breadcrumbs;
