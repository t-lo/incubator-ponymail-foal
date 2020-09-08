#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Parent OAuth endpoint for Pony Mail codename Foal"""

import plugins.server
import plugins.session
import plugins.oauthGeneric
import plugins.oauthGoogle
import plugins.oauthGithub
import typing
import aiohttp.web
import hashlib


async def process(
    server: plugins.server.BaseServer,
    session: plugins.session.SessionObject,
    indata: dict,
) -> typing.Union[dict, aiohttp.web.Response]:

    state = indata.get("state")
    code = indata.get("code")
    id_token = indata.get('id_token')
    oauth_token = indata.get("oauth_token")

    rv: typing.Optional[dict] = None

    # Google OAuth - currently fetches email address only
    if oauth_token and oauth_token.startswith("https://www.googleapis.com/") and id_token:
        rv = await plugins.oauthGoogle.process(indata, session, server)

    # GitHub OAuth - currently fetches email address only
    if indata.get('key', '') == 'github' and code:
        rv = await plugins.oauthGithub.process(indata, session, server)


    # Generic OAuth handler, only one we support for now. Works with ASF OAuth.
    elif state and code and oauth_token:
        rv = await plugins.oauthGeneric.process(indata, session, server)

    if rv:
        # Get UID, fall back to using email address
        uid = rv.get("uid")
        if not uid:
            uid = rv.get("email")
        if uid:
            cid = hashlib.shake_128(
                ("%s-%s" % (rv.get("oauth_domain", "generic"), uid)).encode(
                    "ascii", "ignore"
                )
            ).hexdigest(16)
            cookie = await plugins.session.set_session(
                server,
                cid,
                uid=uid,
                name=rv.get("name") or rv.get("fullname"),
                email=rv.get("email"),
                # Authoritative if OAuth domain is in the authoritative oauth section in ponymail.yaml
                # Required for access to private emails
                authoritative=rv.get("oauth_domain", "generic")
                in server.config.oauth.authoritative_domains,
                oauth_provider=rv.get("oauth_domain", "generic"),
                oauth_data=rv,
            )
            # This could be improved upon, instead of a raw response return value
            return aiohttp.web.Response(
                headers={"set-cookie": cookie, "content-type": "application/json"},
                status=200,
                text='{"okay": true}',
            )

    return {"okay": False, "message": "Could not process OAuth login!"}

def register(server: plugins.server.BaseServer):
    return plugins.server.Endpoint(process)
