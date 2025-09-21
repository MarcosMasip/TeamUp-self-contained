## Frontend multi-stage build
FROM node:14.21.3-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY angular.json tsconfig*.json ./
COPY src ./src
RUN npm run build

FROM nginx:1.27.2-alpine AS runtime
COPY --from=build /app/dist/socialnetworkingapp /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
#Download Node Alpine image
FROM node:14-alpine As build

#Setup the working directory
WORKDIR /app

ENV PATH /app/node_modules/.bin$PATH

COPY package*.json ./

RUN npm isntall

RUN npm install -g @angular/cli

COPY . /app

CMD ng serve --host 0.0.0.0