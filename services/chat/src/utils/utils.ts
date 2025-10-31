export function safeParseJSON(input: any): any {
    if (typeof input === 'string') {
        try {
            return JSON.parse(input);
        } catch (e) {
            console.error("JSON parse error:", e);
            return null;
        }
    }
    return input;
}
