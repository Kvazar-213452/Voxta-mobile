import express, { Express } from 'express';
import { send_gmail } from './head_com/gmail';
import { loadConfig, rebuildConfig, CONFIG } from "./config";

async function main() {
  try {
    await loadConfig("GLOBAL_URL");
    await loadConfig("GLOBAL_DB");
    await loadConfig();

    rebuildConfig();

    const app: Express = express();
    app.use(express.json());

    app.post<{}, any, { data: any[] }>('/send_gmail', async (req, res) => {
      try {
        const { data } = req.body;
        await send_gmail(data[1].toString(), data[0]);
        res.json({ status: 1 });
      } catch (error) {
        console.error(error);
        res.status(500).json({ status: 2 });
      }
    });

    app.listen(CONFIG.PORT, '0.0.0.0', () => {
      console.log(`Сервер запущено на http://0.0.0.0:${CONFIG.PORT}`);
    });

  } catch (error) {
    console.error("Помилка при старті сервера:", error);
    process.exit(1);
  }
}

main();