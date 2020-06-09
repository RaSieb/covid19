import mysql.connector
from mysql.connector import errorcode
import argparse

DB_NAME = 'covid19'
TABLES = {'Patients': "CREATE TABLE `employees` ("
                      "  `ssi_id` varchar(14) NOT NULL,"
                      "  `age` int(11) NOT NULL,"
                      "  `age_group` varchar(16) NOT NULL,"
                      "  `sex` enum('M','F') NOT NULL,"
                      "  `age` enum('0','1','2') NOT NULL,"
                      "  `COVID19_EndDate` date NOT NULL,"
                      "  PRIMARY KEY (`ssi_id`)"
                      ") ENGINE=InnoDB"}


def get_connection():
    try:
        host = input("Please enter the mysql database server IP (defaults to localhost): ")
        host = 'localhost' if len(host.strip(' ')) == 0 else host
        password = input("Please enter the mysql user's database password: ")
        cnxn = mysql.connector.connect(user='covid19', password=password,
                                       host=host,
                                       database=DB_NAME)

    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("Something is wrong with your user name or password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print("Database does not exist")
        else:
            print(err)
    else:
        return cnxn


def check_file(filepath):
    """
    Checks if the supplied path contains a file
    :type filepath: str
    :param filepath: relative path to check
    :return: absolute filepath if it does, print error message and exit otherwise
    """
    if len(filepath) == 0:
        print("file not found")
        exit(-1)
    else:
        return filepath


def create_schema(cnxn):
    cursor = cnxn.cursor()
    try:
        cursor.execute("USE {}".format(DB_NAME))
        for table_name in TABLES:
            table_description = TABLES[table_name]
            try:
                # TODO: drop them all like this: SELECT concat('DROP TABLE IF EXISTS `', table_name, '`;')
                # FROM information_schema.tables
                # WHERE table_schema = 'MyDatabaseName';
                print("Creating table {}: ".format(table_name), end='')
                cursor.execute("DROP TABLE IF EXISTS {}".format(table_name))
                cursor.execute(table_description)
            except mysql.connector.Error as err:
                if err.errno == errorcode.ER_TABLE_EXISTS_ERROR:
                    print("already exists.")
                else:
                    print(err.msg)
            else:
                print("Created the schema")
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_BAD_DB_ERROR:
            print("Database {} does not exists.".format(DB_NAME))
            exit(-1)




def clear_data(cnxn):
    print("Cleared existing data on MariaDB server")


def add_data(cnxn, filepath):
    print("Loaded all data from {}".format(filepath))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='convert a metadata file to SQL relational format and inject to the MariaDB')
    parser.add_argument('file', type=str,
                        help='path to the file to be loaded')
    parser.add_argument('--recreate_schema', dest='re_schema', type=bool, default=True,
                        help='select False to avoid recreating the schema')

    args = parser.parse_args()
    file = check_file(args.file)
    cnx = get_connection()
    if args.re_schema:
        create_schema(cnx)

    clear_data(cnx)
    add_data(cnx, file)

    cnx.close()
