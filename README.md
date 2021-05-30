# docker-stack с образом majordomo + mqtt + zigbee2mqtt
На данный момент проверено на ubuntu server 20.04 LTS на Raspberry Pi 4

#### Установка самого докера:
    sudo apt get update
    sudo apt get upgrade
    sudo apt-get install docker docker-compose

#### Установка Portainer по желанию
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer

#### Развертывание репозитория
Переходим в папку, где будем развертывать контейнер, например /opt, и клонируем репозиторий:
``` 
cd /opt
git clone https://github.com/Fav0rit/favorit_majordomo_docker.git
cd favorit_majordomo_docker
cp sample.env .env
nano .env
```
Вписываем в .env свои логины и пароли и запускаем установку
```
make install
```
После всех операций мы должны получить рабочую композицию сервисов.
Обращаю внимание, что веб-сервер и mqtt-брокер подключены в режиме "host" а значит все их порты доступны напрямую.
Для ручного запуска ```docker-compose up -d```

### TODO
- Сделать скрипт переноса БД в оперативную память
- Настроить автоматическое резервирование БД

#### References
https://github.com/sprintcube/docker-compose-lamp<br>
https://github.com/A-SOM/docker-majordomo<br>
https://github.com/sevrugin/docker-majordomo<br>
