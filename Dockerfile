# Stage 1: Build backend
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS backend
WORKDIR /repo

ARG TARGETPLATFORM
RUN case "${TARGETPLATFORM}" in \
      "linux/arm64") echo "linux-musl-arm64" > /tmp/rid ;; \
      "linux/arm/v7") echo "linux-musl-arm" > /tmp/rid ;; \
      *) echo "linux-musl-x64" > /tmp/rid ;; \
    esac

# Copy project files first for layer caching on restore
COPY src/Directory.Build.props src/Directory.Build.targets src/NuGet.config src/stylecop.json src/
COPY src/Targets/ src/Targets/
COPY src/Libraries/ src/Libraries/
COPY src/NzbDrone/Prowlarr.csproj src/NzbDrone/
COPY src/NzbDrone.Common/Prowlarr.Common.csproj src/NzbDrone.Common/
COPY src/NzbDrone.Console/Prowlarr.Console.csproj src/NzbDrone.Console/
COPY src/NzbDrone.Core/Prowlarr.Core.csproj src/NzbDrone.Core/
COPY src/NzbDrone.Host/Prowlarr.Host.csproj src/NzbDrone.Host/
COPY src/NzbDrone.Mono/Prowlarr.Mono.csproj src/NzbDrone.Mono/
COPY src/NzbDrone.SignalR/Prowlarr.SignalR.csproj src/NzbDrone.SignalR/
COPY src/NzbDrone.Update/Prowlarr.Update.csproj src/NzbDrone.Update/
COPY src/NzbDrone.Windows/Prowlarr.Windows.csproj src/NzbDrone.Windows/
COPY src/Prowlarr.Api.V1/Prowlarr.Api.V1.csproj src/Prowlarr.Api.V1/
COPY src/Prowlarr.Http/Prowlarr.Http.csproj src/Prowlarr.Http/
COPY src/ServiceHelpers/ServiceInstall/ServiceInstall.csproj src/ServiceHelpers/ServiceInstall/
COPY src/ServiceHelpers/ServiceUninstall/ServiceUninstall.csproj src/ServiceHelpers/ServiceUninstall/

RUN dotnet restore src/NzbDrone.Console/Prowlarr.Console.csproj -r "$(cat /tmp/rid)" -p:SelfContained=true -p:EnableAnalyzers=false

# Copy remaining source and build
COPY src/ src/
COPY LICENSE LICENSE

RUN dotnet publish src/NzbDrone.Console/Prowlarr.Console.csproj \
      -c Release \
      -f net8.0 \
      -r "$(cat /tmp/rid)" \
      --self-contained \
      --no-restore \
      -p:EnableAnalyzers=false \
      -o /build/bin && \
    rm -rf /build/bin/Prowlarr.Update /build/bin/Prowlarr.Windows.* \
           /build/bin/ServiceInstall.* /build/bin/ServiceUninstall.*

# Stage 2: Build frontend
FROM node:20-alpine AS frontend
WORKDIR /repo

COPY package.json yarn.lock .yarnrc ./
RUN yarn install --frozen-lockfile --network-timeout 120000

COPY frontend/ frontend/
COPY tsconfig.json ./
RUN yarn build --env production

# Stage 3: Runtime on hotio base
FROM ghcr.io/hotio/base:alpinevpn

EXPOSE 9696
ENV WEBUI_PORTS="9696/tcp"

RUN apk add --no-cache libintl sqlite-libs icu-libs

COPY --from=backend /build/bin ${APP_DIR}/bin
COPY --from=frontend /repo/_output/UI ${APP_DIR}/bin/UI

ARG VERSION
ARG VERSION_BRANCH=develop
RUN echo -e "PackageVersion=${VERSION:-local}\nPackageAuthor=[nitrobass24](https://github.com/nitrobass24)\nUpdateMethod=Docker\nBranch=${VERSION_BRANCH}" \
      > "${APP_DIR}/package_info" && \
    chmod -R u=rwX,go=rX "${APP_DIR}"

COPY root/ /
RUN find /etc/s6-overlay/s6-rc.d -name "run*" -execdir chmod +x {} +
