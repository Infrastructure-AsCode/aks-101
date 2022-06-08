#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0-bullseye-slim AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:6.0-bullseye-slim AS build
WORKDIR /src
COPY ["GuineaPig/GuineaPig.csproj", "GuineaPig/"]
RUN dotnet restore "GuineaPig/GuineaPig.csproj"
COPY . .
WORKDIR "/src/GuineaPig"
RUN dotnet build "GuineaPig.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "GuineaPig.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "GuineaPig.dll"]