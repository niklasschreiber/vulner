using System;
using System.Dynamic;
using System.Linq;
using System.Text.RegularExpressions;

namespace DigitalHR.RequestManagement.WorkflowMaternita.Extensions
{
    public static class ExpandoObjectExtensions
    {
        public static bool HasProperty(this ExpandoObject obj, string propertyName)
        {
            return (obj).Any(pair => pair.Key == propertyName);
        }
    }

    public static class DateTimeExtensions
    {
        private static readonly string pattern = @"^P(((?<Y>[1-9]\d*)Y)?(?<M>[1-9]\d*)M|(?<Y>[1-9]\d*)Y)$";

        private static TimeSpan GetTimeSpan(DateTime obj, int years, int months)
        {
            DateTime clone = obj.AddYears(years);
            clone = clone.AddMonths(months);

            return clone.Subtract(obj);
        }

        private static bool ParseYM(string str, DateTime obj, out TimeSpan? ts)
        {
            Regex rx = new(pattern);
            Match m = rx.Match(str);
            if (m.Success)
            {
                var years = m.Groups["Y"].Value.Length > 0 ? Convert.ToInt32(m.Groups["Y"].Value) : 0;
                var months = m.Groups["M"].Value.Length > 0 ? Convert.ToInt32(m.Groups["M"].Value) : 0;
                ts = GetTimeSpan(obj, years, months);
            }
            else
            {
                ts = null;
            }

            return m.Success;
        }

        public static TimeSpan GetTimeSpan(this DateTime obj, string str)
        {
            TimeSpan? rv = null;
            string _str = str.Trim();
            Regex regex = new(@"\s+");
            var ts = regex.Split(_str);
            if (ts.Length == 1)
            {
                var b = ParseYM(_str, obj, out rv);
                if (!b)
                {
                    rv = TimeSpan.Parse(ts[0]);
                }
            }
            else if (ts.Length == 2)
            {
                var b = ParseYM(ts[0], obj, out rv);
                if (!b)
                {
                    throw new FormatException();
                }
                var ts2 = TimeSpan.Parse(ts[1]);
                return rv.Value + ts2;
            }
            if (!rv.HasValue)
            {
                throw new FormatException();
            }
            return rv.Value;
        }
    }
}