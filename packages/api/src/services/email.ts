import { Resend } from "resend";

const resend = process.env.RESEND_API_KEY
  ? new Resend(process.env.RESEND_API_KEY)
  : null;

export interface BudgetAlertEmail {
  recipient: string;
  tenantName: string;
  categoryName: string;
  currentAmount: number;
  budgetAmount: number;
  percentage: number;
  period: string;
}

export class EmailService {
  async sendBudgetAlert(data: BudgetAlertEmail): Promise<void> {
    if (!resend) {
      console.log("Email (simulated) - Budget alert:", JSON.stringify(data));
      return;
    }

    const { recipient, tenantName, categoryName, currentAmount, budgetAmount, percentage, period } = data;

    await resend.emails.send({
      from: "JagaFinance <alerts@jagafinance.com>",
      to: [recipient],
      subject: `[${tenantName}] Budget Alert: ${categoryName}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: #2563EB; padding: 20px; border-radius: 8px 8px 0 0;">
            <h1 style="color: white; margin: 0;">JagaFinance</h1>
          </div>
          <div style="padding: 24px; border: 1px solid #E5E7EB; border-top: 0;">
            <h2 style="color: #DC2626;">Budget Alert</h2>
            <p>Your <strong>${categoryName}</strong> budget for this ${period.toLowerCase()} has reached <strong>${percentage.toFixed(1)}%</strong>.</p>

            <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
              <tr style="background: #F3F4F6;">
                <td style="padding: 8px; border: 1px solid #E5E7EB;">Budget</td>
                <td style="padding: 8px; border: 1px solid #E5E7EB; text-align: right;">Rp ${budgetAmount.toLocaleString("id-ID")}</td>
              </tr>
              <tr>
                <td style="padding: 8px; border: 1px solid #E5E7EB;">Spent</td>
                <td style="padding: 8px; border: 1px solid #E5E7EB; text-align: right; color: ${percentage > 100 ? "#DC2626" : "#059669"};">Rp ${currentAmount.toLocaleString("id-ID")}</td>
              </tr>
              <tr style="background: #F3F4F6;">
                <td style="padding: 8px; border: 1px solid #E5E7EB;">Remaining</td>
                <td style="padding: 8px; border: 1px solid #E5E7EB; text-align: right;">Rp ${(budgetAmount - currentAmount).toLocaleString("id-ID")}</td>
              </tr>
            </table>

            ${percentage >= 100
              ? `<div style="background: #FEF2F2; padding: 12px; border-radius: 4px; border-left: 4px solid #DC2626;">
                   <p style="color: #DC2626; margin: 0;">Your budget has been exceeded! Consider reviewing your expenses.</p>
                 </div>`
              : `<div style="background: #FFFBEB; padding: 12px; border-radius: 4px; border-left: 4px solid #F59E0B;">
                   <p style="color: #92400E; margin: 0;">Your budget is almost reached. Please review upcoming expenses.</p>
                 </div>`
            }

            <p style="color: #6B7280; font-size: 12px; margin-top: 24px;">
              This is an automated notification from JagaFinance. To change your notification settings, visit your dashboard.
            </p>
          </div>
        </div>
      `,
    });
  }

  async sendInviteEmail(
    recipient: string,
    tenantName: string,
    role: string,
    inviteUrl: string
  ): Promise<void> {
    if (!resend) {
      console.log("Email (simulated) - Invite:", { recipient, tenantName, role, inviteUrl });
      return;
    }

    await resend.emails.send({
      from: "JagaFinance <invites@jagafinance.com>",
      to: [recipient],
      subject: `You're invited to join ${tenantName} on JagaFinance`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: #2563EB; padding: 20px; border-radius: 8px 8px 0 0;">
            <h1 style="color: white; margin: 0;">JagaFinance</h1>
          </div>
          <div style="padding: 24px; border: 1px solid #E5E7EB; border-top: 0;">
            <h2>Join ${tenantName}</h2>
            <p>You have been invited to join <strong>${tenantName}</strong> on JagaFinance as <strong>${role}</strong>.</p>
            <p style="margin: 24px 0;">
              <a href="${inviteUrl}" style="background: #2563EB; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">
                Accept Invitation
              </a>
            </p>
            <p style="color: #6B7280; font-size: 12px;">This invite expires in 7 days.</p>
          </div>
        </div>
      `,
    });
  }

  async sendExportReady(
    recipient: string,
    exportType: string,
    downloadUrl: string
  ): Promise<void> {
    if (!resend) {
      console.log("Email (simulated) - Export ready:", { recipient, exportType, downloadUrl });
      return;
    }

    await resend.emails.send({
      from: "JagaFinance <reports@jagafinance.com>",
      to: [recipient],
      subject: `Your ${exportType} report is ready`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="padding: 24px;">
            <h2>Report Ready</h2>
            <p>Your <strong>${exportType}</strong> export is ready for download.</p>
            <a href="${downloadUrl}" style="background: #2563EB; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">
              Download Report
            </a>
          </div>
        </div>
      `,
    });
  }
}
