FROM mcr.microsoft.com/playwright

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npx playwright install

CMD ["npx", "playwright", "test", "--grep-invert", "@require-wordpress"]
