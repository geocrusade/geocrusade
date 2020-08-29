set -e
docker-compose -f docker-compose.yml down
cd ./modules
docker run --rm -w "/builder" -v "${PWD}:/builder" heroiclabs/nakama-pluginbuilder:2.12.0 build -buildmode=plugin -trimpath -o ./plugin_code.so
cd ..
docker-compose -f docker-compose.yml up
