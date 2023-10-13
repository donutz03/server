import * as bodyParser from 'body-parser';
import * as express from 'express';
import {ProductModel} from './src/product.model';
import {validateOrReject} from 'class-validator';

const app=express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));

('/', async (req,res)  => {
    
    const body = new ProductModel(req.body);
    try {
      await validateOrReject(body); 
      res.send('Valid object!);
    } catch(e) {
  res.send(e);
    }  
  }
)

app.listen(3000,() => console.log('Server is running..'));
