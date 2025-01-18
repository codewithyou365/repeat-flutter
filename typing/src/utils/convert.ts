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

export function toBool(input: any): boolean {
    if (typeof input === 'boolean') {
        return input;
    } else if (typeof input === 'number') {
        return input !== 0;
    } else if (typeof input === 'string') {
        return input.trim().toLowerCase() === 'true';
    } else {
        return false;
    }
}

