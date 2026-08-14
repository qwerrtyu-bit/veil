import requests
import time
import json
from datetime import datetime

BOT_TOKEN = 'veil_bot_3MuO6P1pOOa1t8yz1h9IlAQt04Jezg9N'
SERVER_URL = 'http://localhost:8080'

class VeilBot:
    def __init__(self, token):
        self.token = token
        self.handlers = {}
    
    def command(self, name):
        def decorator(func):
            self.handlers[name] = func
            return func
        return decorator
    
    def send_message(self, chat_id, text):
        try:
            response = requests.post(
                f'{SERVER_URL}/bots/message',
                json={
                    'token': self.token,
                    'chatId': chat_id,
                    'text': text,
                    'from': 'bot'
                },
                timeout=10
            )
            if response.status_code == 200:
                return response.json()
            else:
                print(f"⚠️ Ошибка отправки: {response.status_code}")
                return None
        except Exception as e:
            print(f"⚠️ Ошибка отправки: {e}")
            return None
    
    def get_messages(self, chat_id):
        try:
            response = requests.get(
                f'{SERVER_URL}/poll',
                params={'userId': chat_id},
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                messages = data.get('messages', [])
                # Если messages — это список, возвращаем его
                if isinstance(messages, list):
                    return messages
                return []
            return []
        except Exception as e:
            print(f"⚠️ Ошибка получения сообщений: {e}")
            return []
    
    def run(self, chat_id):
        print(f"🤖 Бот запущен для чата: {chat_id}")
        
        while True:
            try:
                messages = self.get_messages(chat_id)
                
                # Проверяем, что messages — это список
                if not isinstance(messages, list):
                    messages = []
                
                for msg in messages:
                    if not isinstance(msg, dict):
                        continue
                    
                    text = msg.get('text', '').lower()
                    
                    if text in self.handlers:
                        try:
                            self.handlers[text](self, chat_id)
                        except Exception as e:
                            print(f"⚠️ Ошибка в обработчике: {e}")
                    elif text.startswith('/'):
                        self.send_message(chat_id, f'🤔 Неизвестная команда "{text}". Напиши /help')
                
                time.sleep(2)
                
            except KeyboardInterrupt:
                print("\n🛑 Бот остановлен")
                break
            except Exception as e:
                print(f"⚠️ Ошибка: {e}")
                time.sleep(5)

# ============================================================
# СОЗДАЁМ БОТА
# ============================================================

bot = VeilBot(BOT_TOKEN)

@bot.command('/start')
def cmd_start(bot, chat_id):
    bot.send_message(chat_id, '👋 Привет! Я бот Veil. Чем могу помочь?')

@bot.command('/help')
def cmd_help(bot, chat_id):
    bot.send_message(chat_id, 
        '📋 Доступные команды:\n'
        '/start - Приветствие\n'
        '/help - Помощь\n'
        '/time - Время\n'
        '/ping - Проверка\n'
        '/date - Дата'
    )

@bot.command('/time')
def cmd_time(bot, chat_id):
    bot.send_message(chat_id, f'🕐 {datetime.now().strftime("%H:%M:%S")}')

@bot.command('/ping')
def cmd_ping(bot, chat_id):
    bot.send_message(chat_id, '🏓 Pong!')

@bot.command('/date')
def cmd_date(bot, chat_id):
    bot.send_message(chat_id, f'📅 {datetime.now().strftime("%d.%m.%Y")}')

# ============================================================
# ЗАПУСК
# ============================================================

if __name__ == '__main__':
    bot.run('IOSi498u2r87328r9y43gy329rfywyfuwqfwqfhfwuihf')