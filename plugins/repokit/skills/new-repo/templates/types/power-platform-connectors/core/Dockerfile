# Pinned toolchain for generating Power Platform custom-connector definitions.
#
# Node is pinned to 18 on purpose: the converters are unmaintained
# (postman-to-openapi 2023, api-spec-converter 2021 — the latter depends on the
# deprecated `request` module) and do NOT run on current Node. Do not bump the
# Node line or the tool versions without re-testing the whole pipeline.
FROM node:18-bullseye-slim

RUN npm install -g postman-to-openapi@3.0.1 api-spec-converter@2.12.0 @apidevtools/swagger-cli@4.0.4

WORKDIR /work
# The repo is mounted at /work at run time; run:  node scripts/generate.mjs
