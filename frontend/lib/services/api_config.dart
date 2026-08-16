/// Base URL for the NeighbourShare backend API.
///
/// Points at the team's shared backend hosted on Render, which is
/// connected to the shared PostgreSQL database (see database/README.md).
/// No local backend or database install is required to use this.
const String apiBaseUrl = 'https://neighborshare-c2vl.onrender.com/api';

/// Local development URL for the NeighbourShare backend API.
///
/// Points at a local backend instance running on localhost.
/// Requires a local backend and database installation.
/// Uncomment this line to use the local backend.
 // const String apiBaseUrl = 'http://localhost:3000/api';
