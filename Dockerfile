# このDockerfileはSnykスキャンの参照用です。
# 実際のイメージビルドには使用されません。
# ワークフローではDockerHubのkong/kong-gatewayイメージを直接プルしてGHCRに再公開しています。

FROM kong/kong-gateway:latest

# 参照元イメージ
# https://hub.docker.com/r/kong/kong-gateway
