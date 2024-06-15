import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@apollo/server/express4';
import { makeExecutableSchema } from '@graphql-tools/schema';
import express from 'express';
import { createServer } from 'http';
import { WebSocketServer } from 'ws';
import { useServer } from 'graphql-ws/lib/use/ws';
import { PubSub } from 'graphql-subscriptions';
import bodyParser from 'body-parser';
import cors from 'cors';

// Import your schema and resolvers
import { typeDefs } from './schema.js';
import db from './_db.js';

// PubSub instance for subscriptions
const pubsub = new PubSub();

const resolvers = {
  Query: {
    games() {
      return db.games;
    },
    game(_, args) {
      return db.games.find((game) => game.id === args.id);
    },
    authors() {
      return db.authors;
    },
    author(_, args) {
      return db.authors.find((author) => author.id === args.id);
    },
    reviews() {
      return db.reviews;
    },
    review(_, args) {
      return db.reviews.find((review) => review.id === args.id);
    },
  },
  Game: {
    reviews(parent) {
      return db.reviews.filter((r) => r.game_id === parent.id);
    },
  },
  Review: {
    author(parent) {
      return db.authors.find((a) => a.id === parent.author_id);
    },
    game(parent) {
      return db.games.find((g) => g.id === parent.game_id);
    },
  },
  Author: {
    reviews(parent) {
      return db.reviews.filter((r) => r.author_id === parent.id);
    },
  },
  Mutation: {
    addGame(_, args) {
      let game = {
        ...args.game,
        id: Math.floor(Math.random() * 10000).toString(),
      };
      db.games.push(game);
      pubsub.publish('GAME_ADDED', { gameAdded: game });
      return game;
    },
    deleteGame(_, { _id }) {
      db.games = db.games.filter((g) => g.id !== _id);
      return db.games;
    },
    updateGame(_, { id, game }) {
      const gameIndex = db.games.findIndex((g) => g.id === id);
      if (gameIndex === -1) return null;

      const updatedGame = {
        ...db.games[gameIndex],
        ...game,
      };

      db.games[gameIndex] = updatedGame;
      return updatedGame;
    },
  },
  Subscription: {
    gameAdded: {
      subscribe: () => pubsub.asyncIterator(['GAME_ADDED']),
    },
  },
};

// Create an executable schema
const schema = makeExecutableSchema({ typeDefs, resolvers });

// Create an Express app
const app = express();
app.use(cors());
app.use(bodyParser.json());

// Create a new HTTP server
const httpServer = createServer(app);

// Set up Apollo Server
const server = new ApolloServer({
  schema,
  plugins: [
    {
      async serverWillStart() {
        return {
          async drainServer() {
            wsServer.dispose();
          },
        };
      },
    },
  ],
});

// Apply middleware to the Express app
await server.start();
app.use('/graphql', expressMiddleware(server));

// Set up WebSocket server
const wsServer = new WebSocketServer({
  server: httpServer,
  path: '/graphql',
});

// Integrate GraphQL WebSocket server with the same HTTP server
useServer({ schema }, wsServer);

// Start the HTTP server
httpServer.listen(4000, () => {
  console.log(`Server is now running on http://localhost:4000/graphql`);
  console.log(`Subscriptions are now running on ws://localhost:4000/graphql`);
});
