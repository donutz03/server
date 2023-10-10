app.get('/', (req,res)=> {
    throw new Error('BROKEN')
})

app.get('/', (req,res,next) => {
    fs.readFile('/file-does-not-exist', (err,data) => {
        if (err) {
            next(err)
        } else {
            res.send(data)
        }
    })
})

app.get('/user/:id', async(req,res,next) => {
    const user = await getUserById(req.params.id)
    res.send(user)
})

app.get('/', [
    function (req,res,next) {
        fs.writeFile('/inaccessible-path', 'data', next) 
    },
    function (req,res) {
        res.send('OK')
    }
])

app.get('/', (req,res,next) => {
    setTimeout(() => {
        try {
            throw new Error('BROKEN')
        } catch (err) {
            next(err)
        }
    }, 100)
})

app.get('/', (req,res,next) => {
    Promise.resolve().then()(()=> {
        throw new Error('BROKEN')
    }).catch(next)
})

app.get('/', [
    function(req,res,next) {
        fs.readFile('/maybe-valid-file', 'utf-8', (err,data)=> {
            res.locals.data = data;
            next(err)
        })
    },
    function(req,res) {
        res.locals.data = res.locals.data.split(',')[1]
        res.send(res.locals.data)
    }
])

function errorHandler(err,req,res,next) {
    if (res.headersSent) {
        return next(err)
    }
    res.status(500)
    res.render('error', {error: err})
}

app.use((err, req,res,next) => {
    console.error(err.stack)
    res.status(500).send('smth broke!')
})

const bodyParser = require('body-parser')
const methodOverride = require('method-override')

app.use(bodyParser.urlencoded({
    extended: true
}))
app.use(bodyParser.json())
app.use(methodOverride())
app.use((err,req,res,next) =>{})

const bodyParser = require('body-parser')
const methodOverride = require('method-override')

app.use(bodyParser.urlencoded({
    extended: true
}))
app.use(bodyParser.json())
app.use(methodOverride())
app.use(logErrors)
app.use(clientErrorHandler)
app.use(errorHandler)

function logErrors(err,req,res,next) {
    console.error(err.stack)
    next(err)
}

function clientErrorHandler(err,req,res,next) {
    if (req.xhr) {
        req.status(500).send({error: 'smt faild'})
    } else {
        next(err)
    }
}

function errorHandler(err,req,res,next) {
    res.status(500)
    res.render('error', {error: err})
}

app.get('/a_route_behind_paywall',
(res,req,next)=> {
    if (!req.user.hasPaid) {
        next('route')
    } else {
        next()
    }
}, (req,res,next) => {
    PaidContent.find((err,doc)=> {
        if (err) return next(err)
        res.json(doc)
    })
})