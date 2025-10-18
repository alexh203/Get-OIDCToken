function Get-OIDCToken {
    <#
    .SYNOPSIS
         Returns OpenID Connect (OIDC) token from an ADFS server.

    .DESCRIPTION
        This function initiates an OIDC Authorization flow by requesting the client secret then opening the a web browser for user login.
        After the user authenticates, the function receives the authorization code via the provided redirect URI and exchanges it for an access token.

    .PARAMETER clientID
        The client ID registered in ADFS.
    
    .PARAMETER redirectURI
        The redirect URI registered in ADFS where the authorization code will be sent
        
    .PARAMETER scope
        The scope of access requested (e.g., "openid profile email").

    .OUTPUTS
        Returns the access token

    .EXAMPLE
        Get-OIDCToken -clientID "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxx" -redirectURI "http://localhost:8080" -scope "openid email profile"

    .NOTES
        Author: Alex Hawes

    #>

    param (
        [parameter(Mandatory=$true)]
        [string]$clientID,

        [parameter(Mandatory=$true)]
        [string]$redirectURI,

        [parameter(Mandatory=$true)]
        [string]$scope
    )

    $clientSecret = Read-Host "Client secret" -MaskInput
    $adfsAuthority = "https://adfs.example.com/adfs"
    $authUrl = "$adfsAuthority/oauth2/authorize?response_type=code&client_id=$clientId&redirect_uri=$([uri]::EscapeDataString($redirectUri))&scope=$([uri]::EscapeDataString($scope))"
    $msEdge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

    Write-Host "`nOpenning browser for login..."
    Start-Process -FilePath $msEdge -ArgumentList "-inprivate $authUrl"

    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add($redirectURI)
    $listener.Start()
    Write-Host "`nWaiting for authorization code from $redirectURI ... " 

    $context = $listener.GetContext()
    $request = $context.Request
    $code = $request.QueryString["code"]
    $responseString ="
    <html>
        <head>
            <title>Close Window Message</title>
            <style>
                body {
                    display: flex;
                    height: 100;
                    margin: 0;
                    background: linear-gradient(135deg, #6a11cb, #2575fc);
                    font-family: 'Segoe UI';
                    justify-content: center;
                    align-items: center;
                    color: white;
                }
                                                                           
                                                                           
                .message {
                    background-color: rgba(0,0,0,0.4);
                    padding: 2em;
                    border-radius: 10px 100px / 120px;
                    font-size: 2em;
                    text-align: center;
                    animation: pulse 2s infinite ease-in-out; 
                }
                                                                           
                @keyframes pulse {
                    0%, 100% {
                        text-shadow: 0 0 5px #fff,
                          0 0 10px #fff,
                          0 0 20px #6a11cb,
                          0 0 30px #6a11cb,
                          0 0 40px #2575fc;
                    }
                    50% { 
                        text-shadow: 0 0 15px #fff
                          0 0 25px #fff,
                          0 0 40px #6a11cb,
                          0 0 50px #2575fc,
                          0 0 60px #2575fc;
                    }
                </style>
        </head>
        <body>
            <div class='message'>
                You can close this message
            </div>
        </body>
    </html>"
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
    $response = $context.Response
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
    $listener.Stop()

    if (-not $code) {
        Write-Error "Authorization code not found in request."
        exit 1
    }

    Write-Host "`nAuthorization code received: $code"

    $tokenEndpoint = "$adfsAuthority/oauth2/token"
    $body = @{
        client_id = $clientId
        grant_type = "authorization_code"
        code = $code
        redirect_uri = $redirectUri
        scope = $scope
    }

    if ($clientSecret) {
        $body.client_secret = $clientSecret
    }

    try {
        $response = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -ContentType "application/x-www-form-urlencoded" -Body $body
    } 
    catch {
        Write-Error "Token request failed: $_"
        exit 1
    }

    if ($response.id_token) {
        Write-Host "`nID Token (JWT):"
        Write-Output $response.id_token
    }
    else {
        Write-Error "ID token not found in response."
    }

    Write-Host "`nAccess token: "
    Parse-JWTtoken -Token $response.access_token
    Write-Host "`nID token: "
    Parse-JWTtoken -Token $response.id_token
}
