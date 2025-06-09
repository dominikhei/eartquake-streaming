const crypto = require('crypto');

exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;
    const uri = request.uri;
    const querystring = request.querystring;
    
    console.log('Request URI:', uri);
    console.log('Query string:', querystring);
    
    const cognitoDomain = '${cognito_domain}';
    const clientId = '${client_id}';
    const clientSecret = '${client_secret}';
    
    if (uri.startsWith('/callback')) {
        console.log('Handling callback');
        
        const params = new URLSearchParams(querystring);
        const code = params.get('code');
        const state = params.get('state');
        
        if (code) {
            try {
                const tokenResponse = await exchangeCodeForTokens(code, cognitoDomain, clientId, clientSecret, request);
                
                if (tokenResponse.access_token) {
                    let returnUrl = '/';
                    if (state) {
                        try {
                            const stateObj = JSON.parse(Buffer.from(state, 'base64').toString());
                            returnUrl = stateObj.returnUrl || '/';
                        } catch (e) {
                            console.log('Error parsing state:', e);
                        }
                    }
                    
                    return {
                        status: '302',
                        statusDescription: 'Found',
                        headers: {
                            location: [{
                                key: 'Location',
                                value: returnUrl
                            }],
                            'set-cookie': [
                                {
                                    key: 'Set-Cookie',
                                    value: `access_token=$${tokenResponse.access_token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=3600`
                                },
                                {
                                    key: 'Set-Cookie', 
                                    value: `id_token=$${tokenResponse.id_token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=3600`
                                }
                            ]
                        }
                    };
                }
            } catch (error) {
                console.error('Error exchanging code for tokens:', error);
            }
        }
        
        return {
            status: '302',
            statusDescription: 'Found',
            headers: {
                location: [{
                    key: 'Location',
                    value: `https://$${cognitoDomain}.auth.us-east-1.amazoncognito.com/login?client_id=$${clientId}&response_type=code&scope=email+openid+profile&redirect_uri=https://$${headers.host[0].value}/callback`
                }]
            }
        };
    }
    
    const cookies = parseCookies(headers.cookie);
    const accessToken = cookies.access_token;
    
    if (accessToken) {
        console.log('User appears to be authenticated');
        
        if (uri === '/' || uri === '/index.html') {
            request.uri = '/index.$${site_version}.html';
        }
        
        return request;
    }
    
    console.log('No authentication found, redirecting to Cognito');
    
    const state = Buffer.from(JSON.stringify({
        returnUrl: `https://$${headers.host[0].value}$${uri}`
    })).toString('base64');
    
    const loginUrl = `https://$${cognitoDomain}.auth.us-east-1.amazoncognito.com/login?client_id=$${clientId}&response_type=code&scope=email+openid+profile&redirect_uri=https://$${headers.host[0].value}/callback&state=$${state}`;
    
    return {
        status: '302',
        statusDescription: 'Found',
        headers: {
            location: [{
                key: 'Location',
                value: loginUrl
            }]
        }
    };
};

async function exchangeCodeForTokens(code, cognitoDomain, clientId, clientSecret, request) {
    const tokenEndpoint = `https://$${cognitoDomain}.auth.us-east-1.amazoncognito.com/oauth2/token`;
    const redirectUri = `https://$${request.headers.host[0].value}/callback`;
    
    const credentials = Buffer.from(`$${clientId}:$${clientSecret}`).toString('base64');
    
    const body = new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: redirectUri
    }).toString();
    
    const response = await fetch(tokenEndpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': `Basic $${credentials}`
        },
        body: body
    });
    
    if (!response.ok) {
        throw new Error(`Token exchange failed: $${response.status}`);
    }
    
    return await response.json();
}

function parseCookies(cookieHeader) {
    const cookies = {};
    if (cookieHeader) {
        cookieHeader.forEach(header => {
            header.value.split(';').forEach(cookie => {
                const [name, value] = cookie.trim().split('=');
                if (name && value) {
                    cookies[name] = value;
                }
            });
        });
    }
    return cookies;
}