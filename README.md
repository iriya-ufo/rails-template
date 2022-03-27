# Rails Application Template

## Getting Started

### Build docker image

```
$ make build
```

### Setup credentials

```
$ make sh # Enter the container

$ apt-get update && apt-get install vim

$ EDITOR="vim" bin/rails credentials:edit -e test
$ EDITOR="vim" bin/rails credentials:edit -e development
$ EDITOR="vim" bin/rails credentials:edit -e staging
$ EDITOR="vim" bin/rails credentials:edit -e production
```

### Start the server

```
$ make up
$ make dbc # db create
$ make dbm # db migrate
```

Open http://localhost:3000
