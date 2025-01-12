export function toNumber(input: any): number {
    if (typeof input === 'number') {
        return input;
    } else if (typeof input === 'string') {
        const parsed = parseInt(input, 10);
        return isNaN(parsed) ? 0 : parsed;
    } else {
        return 0;
    }
}