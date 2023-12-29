export type TypographySizes = "small" | "medium" | "large";

export type AlertData = { 
    status:"info" | "warning" | "success" | "error" | "loading" | undefined, 
    title:string, 
    description:string 
}
