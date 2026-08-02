exports.handler = async () => ({
  statusCode: 503,
  body: JSON.stringify({ message: "Deployment pending" })
});
