ARG NUGET_GITHUB_CYCODEHQ_PASSWORD=secret_value
ARG ENV=alpine_v6

FROM us-east1-docker.pkg.dev/cycode-artifacts/cycodehq/aspnet-sdk-net6:latest AS build-env
ARG NUGET_GITHUB_CYCODEHQ_PASSWORD
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY ./CommonProjectFile ./CommonProjectFile
COPY ./Cycode.Marketplace.Runners.GitCloner ./Cycode.Marketplace.Runners.GitCloner
WORKDIR /app/Cycode.Marketplace.Runners.GitCloner/Cycode.GitCloner.EntryPoint

# Configure cycode nuget repoitory, More info in /README.md file 
COPY ./_nuget.config /tmp/nuget.config
RUN dotnet restore --configfile /tmp/nuget.config


###### publish ######
FROM build-env AS publish
RUN sudo dotnet publish --no-restore -c Release -o out


###### test ######
FROM build-env AS test
ARG NUGET_GITHUB_CYCODEHQ_PASSWORD
ARG TESTS_DIR
COPY --from=build-env ./${TESTS_DIR} /app/${TESTS_DIR}
COPY --from=0 ./_nuget.config /tmp/nuget.config
WORKDIR /app/${TESTS_DIR}
RUN sh -c '[ -z "${TESTS_DIR}" ]' || dotnet restore --configfile /tmp/nuget.config
ENTRYPOINT ["dotnet", "Cycode.GitCloner.EntryPoint.dll"]
CMD ["dotnet", "test","--no-restore","--verbosity" ,"minimal" ,"--filter" ,"Category!=Integration","--collect:\"XPlat Code Coverage\"","--logger:trx"]
ENTRYPOINT ["dotnet", "Cycode.GitCloner.EntryPoint.dll"]


###### runtime image ######
FROM us-east1-docker.pkg.dev/cycode-artifacts/cycodehq/aspnet-runtime-net6:latest
WORKDIR /app
ARG VERSION
RUN echo "$VERSION" >> VERSION.txt
COPY --from=publish /app/Cycode.Marketplace.Runners.GitCloner/Cycode.GitCloner.EntryPoint/out .
USER cycode
EXPOSE -80
ENTRYPOINT ["dotnet", "Cycode.GitCloner.EntryPoint.dll"]
