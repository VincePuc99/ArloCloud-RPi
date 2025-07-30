import os
import hashlib
import asyncio
import watchdog

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from telegram.ext import Application, CallbackQueryHandler, CommandHandler, ContextTypes, MessageHandler, filters
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update

# Argument Parser for Token and CHATID
parser = argparse.ArgumentParser()
parser.add_argument('api_token', type=str, help='Telegram API token')
parser.add_argument('chat_id', type=str, help='Telegram chat ID')
args = parser.parse_args()

# Bot Init
TOKEN = args.api_token
CHATID = args.chat_id
script_dir = os.path.dirname(os.path.realpath(__file__))
DIR = os.path.join(script_dir, "ArloExposed/arlo/")

##################################################### DM

async def ignore_private_messages(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.message.chat.type == 'private':
        return

##################################################### Arlo

class VideoHandler(FileSystemEventHandler):
    def __init__(self, queue):
        self.queue = queue

    def on_modified(self, event):
        if event.is_directory:
            return
        if event.src_path.endswith(".mp4"):
            asyncio.run_coroutine_threadsafe(self.queue.put(event.src_path), loop)

def calculate_file_hash(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def wait_for_file_to_stabilize(file_path, max_wait_time=10, check_interval=0.5):
    last_size = -1
    elapsed_time = 0

    while elapsed_time < max_wait_time:
        current_size = os.path.getsize(file_path)
        if current_size == last_size:
            return True  
        last_size = current_size
        time.sleep(check_interval)
        elapsed_time += check_interval

    return False

async def process_videos(queue):
    while True:
        video_path = await queue.get()

        ################### LOG
        log_file_path = os.path.join(os.path.dirname(__file__), "mp4_hashes.log")
            
        if os.path.exists(log_file_path):
            with open(log_file_path, "r") as log_file:
                existing_hashes = set(line.strip() for line in log_file)
        else:
            existing_hashes = set()
        ################### LOG

        attempt = 0
        while not wait_for_file_to_stabilize(video_path):
            attempt += 1
            if attempt >= 10: 
                queue.task_done()
                break
            await asyncio.sleep(2)

        else:  # File stable? process it
            with open(log_file_path, "a") as log_file:
                file_hash = calculate_file_hash(video_path)
                if file_hash not in existing_hashes:  # hash not in set
                    await GContext.bot.send_video(chat_id=CHATID, video=video_path)
                    log_file.write(f"{file_hash}\n")
                    existing_hashes.add(file_hash)

        queue.task_done()

############################### MAIN

async def main():

    application = Application.builder().token(TOKEN).build()

    application.add_handler(MessageHandler(filters.ChatType.PRIVATE, ignore_private_messages))

    await application.initialize()
    await application.start()
    await application.updater.start_polling()

    global loop
    loop = asyncio.get_event_loop()
    queue = asyncio.Queue()

    event_handler = VideoHandler(queue)
    observer = Observer()
    observer.schedule(event_handler, DIR, recursive=True)
    observer.start()

    try:
        await process_videos(queue) 
    except asyncio.CancelledError:
        pass
    finally:
        observer.stop()
        observer.join()

    await application.updater.stop()
    await application.stop()
    await application.shutdown()

if __name__ == '__main__':
    asyncio.run(main())
