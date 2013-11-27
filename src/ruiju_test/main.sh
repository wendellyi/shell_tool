#! /bin/sh

function execute_sql ()
{
    sql_file=$1
    /home/ippbx/mysql/bin/mysql IPS_3000 -h localhost -uroot < $sql_file
}

function clean_data ()
{
    echo "now clean data ..."
    execute_sql clean_data.sql
}

function insert_account ()
{
    echo "now create inserting account sql script ..."
    chmod +x insert_account.sh
    ./insert_account.sh > insert_account.sql
    
    echo "execute inserting account sql scripte ..."
    execute_sql insert_account.sql
}

function insert_sipt_account ()
{
    echo "now create inserting sipt sql scripte ..."
    chmod +x sipt_add.sh
    ./sipt_add.sh > sipt_add.sql
    
    echo "execute inserting sipt sql scripte ..."
    execute_sql sipt_add.sql
}

clean_data
insert_account
insert_sipt_account
