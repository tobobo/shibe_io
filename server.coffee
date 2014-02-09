express = require("express")

app = express()

app.use express.bodyParser()

require("./routes.coffee")(app)

app.listen Number(process.env.PORT or 8888)
