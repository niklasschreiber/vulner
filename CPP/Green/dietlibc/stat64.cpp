void PerconaFTEngine::Stats(Context& ctx, std::string& str)
 {
     str.append("perconaft_version:").append(stringfromll(DB_VERSION_MAJOR)).append(".").append(stringfromll(DB_VERSION_MINOR)).append(".").append(
             stringfromll(DB_VERSION_PATCH)).append("\r\n");
     DataArray nss;
     ListNameSpaces(ctx, nss);
     PerconaFTLocalContext& local_ctx = g_local_ctx.GetValue();
     for (size_t i = 0; i < nss.size(); i++)
     {
         DB* db = GetFTDB(ctx, nss[i], false);
         if (NULL == db)
             continue;
         str.append("\r\nDB[").append(nss[i].AsString()).append("] Stats:\r\n");
         DB_BTREE_STAT64 st;
         memset(&st, 0, sizeof(st));
         db->stat64(db, local_ctx.transc.Peek(), &st);
         str.append("bt_nkeys:").append(stringfromll(st.bt_nkeys)).append("\r\n");
         str.append("bt_ndata:").append(stringfromll(st.bt_ndata)).append("\r\n");
         str.append("bt_fsize:").append(stringfromll(st.bt_fsize)).append("\r\n");
         str.append("bt_dsize:").append(stringfromll(st.bt_dsize)).append("\r\n");
         str.append("bt_create_time_sec:").append(stringfromll(st.bt_create_time_sec)).append("\r\n");
         str.append("bt_modify_time_sec:").append(stringfromll(st.bt_modify_time_sec)).append("\r\n");
         str.append("bt_verify_time_sec:").append(stringfromll(st.bt_verify_time_sec)).append("\r\n");
     }
 }