import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { Model, Types } from 'mongoose';
import * as admin from 'firebase-admin';
import {
  Notification,
  NotificationDocument,
  NotificationType,
} from './schemas/notification.schema';
import { BloodType } from '../../common/enums/blood-type.enum';
import { UserDocument } from '../users/schemas/user.schema';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private firebaseInitialized = false;

  constructor(
    @InjectModel(Notification.name)
    private notificationModel: Model<NotificationDocument>,
    private config: ConfigService,
  ) {
    this.initFirebase();
  }

  private initFirebase() {
    const projectId = this.config.get('FIREBASE_PROJECT_ID');
    const privateKey = this.config.get('FIREBASE_PRIVATE_KEY');

    if (!projectId || projectId.startsWith('your_') || !privateKey || privateKey.startsWith('your_')) {
      this.logger.warn('Firebase not configured — push notifications disabled');
      return;
    }

    try {
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail: this.config.get('FIREBASE_CLIENT_EMAIL'),
            privateKey: privateKey.replace(/\\n/g, '\n'),
          }),
        });
        this.firebaseInitialized = true;
        this.logger.log('Firebase initialized');
      }
    } catch (err) {
      this.logger.warn(`Firebase init failed: ${err.message} — push notifications disabled`);
    }
  }

  async sendShortageAlert(
    donors: UserDocument[],
    bloodType: BloodType,
    centerName: string,
    centerDistance?: number,
  ): Promise<void> {
    const title = 'Urgent Blood Donation Needed';
    const body = `Current stock of ${bloodType} blood has reached a critical level. Please help replenish local blood reserves by donating at your nearest blood donation center.${centerName ? `\n\nNearest Center: ${centerName}${centerDistance ? `\nDistance: ${centerDistance.toFixed(1)} km` : ''}` : ''}`;

    const notifications = donors.map((donor) => ({
      userId: donor._id,
      title,
      body,
      type: NotificationType.SHORTAGE_ALERT,
      bloodType,
    }));

    await this.notificationModel.insertMany(notifications);

    const tokens = donors.map((d) => d.fcmToken).filter(Boolean);
    if (tokens.length && this.firebaseInitialized) {
      await this.sendFcmMulticast(tokens, title, body, {
        type: NotificationType.SHORTAGE_ALERT,
        bloodType,
      });
    }

    await this.notificationModel.updateMany(
      { userId: { $in: donors.map((d) => d._id) }, type: NotificationType.SHORTAGE_ALERT, isSent: false },
      { isSent: true, sentAt: new Date() },
    );
  }

  private async sendFcmMulticast(
    tokens: string[],
    title: string,
    body: string,
    data: Record<string, string>,
  ): Promise<void> {
    const BATCH = 500;
    for (let i = 0; i < tokens.length; i += BATCH) {
      const batch = tokens.slice(i, i + BATCH);
      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: batch,
          notification: { title, body },
          data,
          android: { priority: 'high' },
          apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        });
        this.logger.log(`FCM sent: ${response.successCount} ok, ${response.failureCount} failed`);
      } catch (err) {
        this.logger.error('FCM multicast error', err);
      }
    }
  }

  async findByUser(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [notifications, total, unread] = await Promise.all([
      this.notificationModel
        .find({ userId })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      this.notificationModel.countDocuments({ userId }),
      this.notificationModel.countDocuments({ userId, isRead: false }),
    ]);
    return { notifications, total, unread, page, limit };
  }

  async markRead(userId: string, notificationId: string): Promise<void> {
    await this.notificationModel.findOneAndUpdate(
      { _id: notificationId, userId },
      { isRead: true },
    );
  }

  async markAllRead(userId: string): Promise<void> {
    await this.notificationModel.updateMany({ userId, isRead: false }, { isRead: true });
  }
}
