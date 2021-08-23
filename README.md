# Shared infrastructure

## Infrastructure
### Local
The local infrastructure will start a postgres container and a pgadmin container.  

The postgres table will create a default database with a name of `time` and map the data folder to `./local/database/data/`.  

#### Start
```bash
docker compose -f docker-compose.yml up -d
```

#### Down
```bash
docker compose -f docker-compose.yml down
```

#### Remove
Run if the containers have stopped
```bash
docker compose -f docker-compose.yml rm
```

#### Setup pgadmin
1. Go to [http://localhost:58080/](http://localhost:58080/)
2. Right click on `Servers` go to `Create >>> Server` 
3. Create connection
   1. Go to `Connection`
   2. Set the `Host name/address` field to `db`
   3. Set the `Username` field to `admin` 
   4. Set the `Password` field to `Password21` 
   5. Click save
