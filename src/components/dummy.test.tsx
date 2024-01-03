import { render, screen } from "@testing-library/react";
import Heading from "./Heading";
import "@testing-library/jest-dom";

test("Renders the Heading component", () => {
  render(<Heading>Something</Heading>);
  expect(screen.getByText("Something")).toBeVisible();
});
