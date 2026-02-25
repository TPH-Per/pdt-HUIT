import animate from "tailwindcss-animate"

/** @type {import('tailwindcss').Config} */
export default {
    darkMode: ["class"],
    safelist: ["dark"],
    prefix: "",
    content: [
        "./index.html",
        "./src/**/*.{vue,js,ts,jsx,tsx}",
    ],
    theme: {
        container: {
            center: true,
            padding: "2rem",
            screens: {
                "2xl": "1400px",
            },
        },
        extend: {
            colors: {
                border: "hsl(var(--border))",
                input: "hsl(var(--input))",
                ring: "hsl(var(--ring))",
                background: "hsl(var(--background))",
                foreground: "hsl(var(--foreground))",
                primary: {
                    DEFAULT: "hsl(var(--primary))",
                    foreground: "hsl(var(--primary-foreground))",
                    50: '#e6eef5',
                    100: '#ccdcea',
                    200: '#99b9d5',
                    300: '#6697c0',
                    400: '#3374ab',
                    500: '#003865',   // HUIT Primary Blue
                    600: '#0B4271',
                    700: '#002d51',
                    800: '#00223d',
                    900: '#001728',
                },
                secondary: {
                    DEFAULT: "hsl(var(--secondary))",
                    foreground: "hsl(var(--secondary-foreground))",
                },
                destructive: {
                    DEFAULT: "hsl(var(--destructive))",
                    foreground: "hsl(var(--destructive-foreground))",
                },
                muted: {
                    DEFAULT: "hsl(var(--muted))",
                    foreground: "hsl(var(--muted-foreground))",
                },
                accent: {
                    DEFAULT: "hsl(var(--accent))",
                    foreground: "hsl(var(--accent-foreground))",
                    50: '#fde8ea',
                    100: '#fbd1d5',
                    200: '#f6a3aa',
                    300: '#f27580',
                    400: '#ed4755',
                    500: '#D31826',   // HUIT Accent Red
                    600: '#E11F26',
                    700: '#a91320',
                    800: '#7f0e18',
                    900: '#540910',
                },
                popover: {
                    DEFAULT: "hsl(var(--popover))",
                    foreground: "hsl(var(--popover-foreground))",
                },
                card: {
                    DEFAULT: "hsl(var(--card))",
                    foreground: "hsl(var(--card-foreground))",
                },
                // HUIT Theme Colors
                huit: {
                    DEFAULT: '#003865',
                    foreground: '#ffffff',
                    50: '#e6eef5',
                    100: '#ccdcea',
                    200: '#99b9d5',
                    300: '#6697c0',
                    400: '#3374ab',
                    500: '#003865',
                    600: '#0B4271',
                    700: '#002d51',
                    800: '#00223d',
                    900: '#001728',
                    red: '#D31826',
                },
                // Status colors
                success: {
                    DEFAULT: '#28A745',
                    50: '#eafbef',
                    500: '#28A745',
                    600: '#218838',
                },
                warning: {
                    DEFAULT: '#FFC107',
                    50: '#fff8e0',
                    500: '#FFC107',
                    600: '#F39C12',
                },
                danger: {
                    DEFAULT: '#D31826',
                    50: '#fde8ea',
                    500: '#D31826',
                    600: '#a91320',
                },
            },
            borderRadius: {
                xl: "calc(var(--radius) + 4px)",
                lg: "var(--radius)",
                md: "calc(var(--radius) - 2px)",
                sm: "calc(var(--radius) - 4px)",
            },
            keyframes: {
                "accordion-down": {
                    from: { height: 0 },
                    to: { height: "var(--radix-accordion-content-height)" },
                },
                "accordion-up": {
                    from: { height: "var(--radix-accordion-content-height)" },
                    to: { height: 0 },
                },
            },
            animation: {
                "accordion-down": "accordion-down 0.2s ease-out",
                "accordion-up": "accordion-up 0.2s ease-out",
            },
        },
    },
    plugins: [animate],
}
