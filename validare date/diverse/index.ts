app.get('/:id', (req,res)=>{
  const stringId=req.params.id;
  const conversionOne=parseInt(stringId,10);
  const conversionTwo =+stringId;

  if(isNan(conversionOne)){
    res.send('Eroare, numar invalid');
  }
  else{
    res.send('Numar valid!);
  }
})

