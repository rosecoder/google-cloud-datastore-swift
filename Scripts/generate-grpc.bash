SOURCES_ROOT="$(pwd)/Sources"

rm -rf ${SOURCES_ROOT}/*/gRPC_generated/*

cd googleapis/

echo "Generating gRPC code for Datastore..."
protoc google/datastore/v1/*.proto google/type/latlng.proto \
  --swift_opt=Visibility=Package \
  --swift_out=${SOURCES_ROOT}/GoogleCloudDatastore/gRPC_generated/ \
  --grpc-swift_opt=Client=true,Server=false \
  --grpc-swift_opt=Visibility=Package \
  --grpc-swift_out=${SOURCES_ROOT}/GoogleCloudDatastore/gRPC_generated/
