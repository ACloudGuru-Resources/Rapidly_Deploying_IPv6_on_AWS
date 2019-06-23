<html><meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <title>What Is My IP Address!</title>
        <body>
                <div id="tools" class="tools">
                        <p>Your IP:</p>
                </div>
                <div id="ip-lookup" class="tools">
                        <?php if ($_SERVER["HTTP_X_FORWARDED_FOR"] != "") {
                                $IP = $_SERVER["HTTP_X_FORWARDED_FOR"];
                                $proxy = $_SERVER["REMOTE_ADDR"];
                                $host = @gethostbyaddr($_SERVER["HTTP_X_FORWARDED_FOR"]);
                        } else {
                                $IP = $_SERVER["REMOTE_ADDR"];
                                $host = @gethostbyaddr($_SERVER["REMOTE_ADDR"]);
                        } ?>
                        <h1><?php echo $IP; ?></h1>
                </div>
        </body>
</html>
