const express = require('express')
const app = express()

app.get('/', (req,res)=>{
    res.send('hello world')
})

app.get('/', (req,res) => {
    res.send('GET req sent to homepage');
})

app.post('/', (req,res) => {
    res.send('POST req to homepage');
})

app.all('/secret', (req,res,next)=>{
    console.log('access');
    next();
})

app.get('/', (req,res) => {
    res.send('root');
})

app.get('/about', (req,res)=> {
    res.send('about');
})

app.get('/random.text', (req,res)=> {
    res.send('random.text');
})

app.get('/ab?cd', (req,res)=>{
    res.send('ab?cd');
})

app.get('/ab+cd', (req,res)=>{
    res.send('ab+cd');
})

app.get('/ab*cd', (req,res)=> {
    res.send('ab*cd')
})

app.get(/a/, (req,res) => {
    res.send('/a/');
})

app.get(/.*fly$/, (req,res)=> {
    res.send('/.*fly$/')
})

// Route path: /users/:userId/books/:bookId
// Request URL: http://localhost:3000/users/34/books/8989
// req.params: {"userId": "34", "bookId": "8989"}

app.get('/users/:userId/books/:bookId', (req,res) =>{
    res.send(req.params)
})

// Route path: /flights/:from-:to
// Request URL: http://localhost:3000/flights/LAX-SFO
// req.params: {"from": "LAX", "to": "SFO"}

// Route path: /plantae/:genus.:species
// Request URL: http://localhost:3000/plantae/Prunus.persica
// req.params: {"genus": "Prunus", "species": "persica"}


// Route path: /user/:userId(\d+)
// Request URL: http://localhost:3000/user/42
// req.params: {"userId": "42"}

app.get('/example/a', (req,res) => {
   res.send('Hello from A!') 
})

app.get('/example/b', (req,res,next)=> {
    console.log('the response will be send by the next function...')
    next()   
}, (req,res) => {
    res.send('Hello from B!')
})

// const cb0 = function(req,res,next) {
//     console.log('CB0')
//     next()
// }

// const cb1 = function(req,res,next) {
//     console.log('CB1')
//     next()
// }

// const cb2 = function(req,res) {
//     res.send('Hello from C!')
// }

// app.get('/example/c', [cb0, cb1, cb2])

const cb0 = function(req,res,next) {
    console.log('CB0')
    next()
}


const cb1 = function (req,res,next) {
    console.log('CB1');
    next()
}

app.get('/example/d', [cb0, cb1], (req,res,next) => {
    console.log('the res will be send the the next func')
    next()
}, (req,res) => {
    res.send('Hello from D!')
})

app.route('/book')
    .get((req,res) => {
        res.send('Get a random book!')
    })
    .post((req,res) => {
        res.send('Add a book')
    })
    .put((req,res)=> {
        res.send('Update the book')
    });

const express = require('express')
const router = express.Router()

router.use((req,res,next) => {
    console.log('Time: ', Date.now())
    next()
})
router.get('/', (req,res) => {
    res.send('Birds home page')
})

router.get('/about', (req,res)=> {
    res.send('abt birds')
})

module.exports = router

const birds = require('./birds')
app.use('/birds', birds)



























