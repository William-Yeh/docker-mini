About the Slides
===

The slides are authored in [remark](https://github.com/gnab/remark) + [remark-zoom](https://github.com/William-Yeh/remark-zoom).


## To view the slides online

Put these files on a host. Then, use any modern web browser to open them.


## To view the slides locally

If you're using Firefox, just open the `index.html` file.

If you're using other browsers, follow these steps:


1. Start a local web server, and set the document root on this directory, e.g.,

   ```
   $ python -m SimpleHTTPServer
   Serving HTTP on 0.0.0.0 port 8000 ...
   ```

   Or just start a Dockerized nginx image:
   ```
   $ docker-compose up -d
   ```

2. Use any modern web browser to connect to the server's document root, e.g.,

   ```
   http://localhost:8000/
   ```

See https://github.com/gnab/remark/wiki#external-markdown for more details.

