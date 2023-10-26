import { Outlet } from "react-router-dom";

export const BlankPage = () => {
    return (
        <div className="blank_page">
            <Outlet />
        </div>
    );
}