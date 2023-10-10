// npm install cassandra-driver

const cassandra = require('cassandra')
const client =new cassandra.Client({contactPoints: ['localhost']})

client.execute('select key from system.local', (err,result)=>{
    if (err) throw err;
    console.log(result.rows[0])
})

// npm install couchbase

const couchbase=require('couchbase')
const bucket = (new
    couchbase.Cluster('http://localhost:8091')).openBucket('bucketName')

// bucket.insert('document-key', {name: 'Matt', shoeSize: 13}, (err,result)={
//     if (err) {
//         console.log(err);
//     } else {
//         console.log(result);
//     }
// })

const n1ql = 'SELECT d.* FROM `bucketName` d WHERE shoeSize = $1'
const query = N1qlQuery.fromString(n1ql)
bucket.query(query, [13], (err,result)=> {
    if (err) {
        console.log(err)
    } else {
        console.log(result)
    }
})


// npm install nano
const nano = require('nano')('https://localhost:5984')
nano.db.create('books')
const books = nano.db.use('books')

books.insert({name: 'The Art of war'}, null, (err, body) => {
    if (err) {
        console.log(err)
    } else {
        console.log(body)
    }
})

books.list((err,body)=> {
    if (err) {
        console.log(err)
    } else {
        console.log(body.rows)
    }
})

// npm install level levelup leveldown
const levelup = require('levelup')
const db = levelup('./mydb')
db.put('name','LevelUP', (err)) => {
    if (err) return console.log('Ooops!', err)
}

db.get('n', (err, val) => {
    if (err) return console.log('a', err);

    console.log(`n=${val}`)
})

// npm install mysql
const m = require('mysql')
const c = mysql.createConnection({
    host: 'localhost',
    user: 'dbuser',
    password: '12111111111111111',
    database: 'abcd'
})

c.connect()

c.query('SELECT 1 + 1 AS solution', (e,r,f)=> {
    if (e) throw e
    console.log(r[0].s)
} )

c.end()

// npm i mongodb

const MC = require('mogodb').MongoClient

MC.connect('mongodb://localhost:27017/animals', (e,d) =>{ 
    if (e) throw e
    d.collection('a').find().toArray((e,r)=>{
        if (e) throw e
        console.log(r)
    })
})

const mc = require('mongodb').MongoClient
mc.connect('mongodb://localhost:27017/a', (e,c)=>{
    if (e) throw e
    const db = c.db('a')

    db.collection('m').find().toArray((e,r) => {
        if (err) throw err
        console.log(r)
    })
})

