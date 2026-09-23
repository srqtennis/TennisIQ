# Public app support pages

Published locations:

- https://srq.tennis/tennis-iq/privacy/
- https://srq.tennis/tennis-iq/support/

`tennis-iq/` contains the exact static files published to the existing Netlify site. `release/website-deployment.json` records the deployment, original rollback target, complete file/function preservation checks and successful live checks.

Future srq.tennis deployments must preserve these paths. Include these files in that site's static publish output; a whole-site replacement that omits them can remove the app's support/privacy pages. The older local `clawd/websites/srq-tennis` tree is not the source of the currently deployed TanStack site, so it was not used to rebuild production.

The native app also contains a readable offline privacy policy and links to these public pages. Update both versions when data practices change. Tour Pass server features are not part of the current app or this policy; a future service needs its own privacy review before launch.
