/*
From: http://docs.mongodb.org/manual/core/authentication/
To authenticate a client in MongoDB, you must add a corresponding user to MongoDB. 
When adding a user, you create the user in a specific database. 
Together, the user’s name and database serve as a unique identifier for that user. 
That is, if two users have the same name but are created in different databases, they are two separate users.


Mongo roles: http://docs.mongodb.org/manual/reference/built-in-roles/
*/
conn = new Mongo();
db = conn.getDB("admin");

db.createUser(
	{
		user: 'minmaster', 
		pwd: mongoPassword, 
		roles: [ 'root' ]
	}
);
db = conn.getDB("spidadb");
db.createUser(
	{
		user: 'minmaster', 
		pwd: mongoPassword, 
		roles: [ 'dbOwner', 'userAdmin' ]
	}
);